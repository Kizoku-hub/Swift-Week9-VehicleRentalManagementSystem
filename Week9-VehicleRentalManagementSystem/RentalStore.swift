import Foundation
import Combine

@MainActor
final class RentalStore: ObservableObject {
    @Published private(set) var vehicles: [Vehicle] = []
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var rentals: [Rental] = []
    @Published var currentCustomerID = "M001"
    let managerID = "M001"

    init() { seed() }
    var currentCustomer: Customer { customers.first(where: { $0.id == currentCustomerID }) ?? customers[0] }
    var isManager: Bool { currentCustomer.isManager }
    var activeVehicles: [Vehicle] { vehicles.filter { !$0.isArchived } }
    var activeCustomers: [Customer] { customers.filter { !$0.isArchived } }
    func vehicle(_ id: String) -> Vehicle? { vehicles.first { $0.id == id } }
    func customer(_ id: String) -> Customer? { customers.first { $0.id == id } }
    func rentals(customer id: String) -> [Rental] { rentals.filter { $0.customerID == id }.sorted { $0.startDate > $1.startDate } }
    func rentals(vehicle id: String) -> [Rental] { rentals.filter { $0.vehicleID == id }.sorted { $0.startDate > $1.startDate } }
    func managerOnly() throws { guard isManager else { throw RentalError.invalid("Manager permission is required.") } }
    func switchAccount(_ id: String) {
        // A customer can switch back to the manager demo account, but cannot impersonate another customer.
        guard isManager || id == managerID || id == currentCustomerID else { return }
        if let c = customer(id), !c.isArchived { currentCustomerID = id }
    }

    func addCustomer(name: String, phone: String, email: String, address: String) throws {
        try managerOnly()
        let n = (customers.compactMap { Int($0.id.dropFirst()) }.max() ?? 0) + 1
        customers.append(try Customer(id: String(format: "C%03d", n), name: name, phone: phone, email: email, address: address))
    }
    func updateCustomer(_ c: Customer, name: String, phone: String, email: String, address: String) throws {
        guard isManager || currentCustomerID == c.id else { throw RentalError.invalid("You can only edit your own profile.") }
        try c.updateContact(name: name, phone: phone, email: email, address: address)
    }
    func archiveCustomer(_ c: Customer) throws {
        try managerOnly()
        guard c.id != managerID else { throw RentalError.invalid("The manager account cannot be archived.") }
        c.archive()
        if currentCustomerID == c.id { currentCustomerID = managerID }
    }

    func addVehicle(type: VehicleType, id: String, name: String, maker: String, rate: Double, a: String, b: String) throws {
        try managerOnly()
        guard vehicle(id) == nil else { throw RentalError.invalid("Vehicle ID already exists.") }
        let v: Vehicle
        switch type {
        case .car:
            guard let seats = Int(a), let fee = Double(b) else { throw RentalError.invalid("Enter valid seats and service charge.") }
            v = try Car(id: id, name: name, manufacturer: maker, dailyRate: rate, seats: seats, serviceCharge: fee)
        case .motorcycle:
            guard let cc = Int(a), let cat = EngineCategory(rawValue: b) else { throw RentalError.invalid("Enter valid engine specifications.") }
            v = try Motorcycle(id: id, name: name, manufacturer: maker, dailyRate: rate, engineCC: cc, category: cat)
        case .electricBicycle:
            guard let range = Double(a), let fee = Double(b) else { throw RentalError.invalid("Enter valid battery specifications.") }
            v = try ElectricBicycle(id: id, name: name, manufacturer: maker, dailyRate: rate, rangeKM: range, batteryFee: fee)
        }
        vehicles.append(v)
    }
    func updateVehicle(_ v: Vehicle, name: String, maker: String, rate: Double, condition: VehicleCondition, a: String, b: String) throws {
        try managerOnly()
        try v.updateGeneralInfo(name: name, manufacturer: maker, dailyRate: rate)
        v.updateCondition(condition)
        if let x = v as? Car {
            guard let seats = Int(a), let fee = Double(b) else { throw RentalError.invalid("Invalid car specifications.") }
            try x.updateSpecs(seats: seats, fee: fee)
        } else if let x = v as? Motorcycle {
            guard let cc = Int(a), let cat = EngineCategory(rawValue: b) else { throw RentalError.invalid("Invalid motorcycle specifications.") }
            try x.updateSpecs(cc: cc, category: cat)
        } else if let x = v as? ElectricBicycle {
            guard let range = Double(a), let fee = Double(b) else { throw RentalError.invalid("Invalid e-bike specifications.") }
            try x.updateSpecs(range: range, fee: fee)
        }
    }
    func archiveVehicle(_ v: Vehicle) throws {
        try managerOnly()
        guard v.availability == .available else { throw RentalError.invalid("Return the vehicle before archiving it.") }
        v.archive()
    }
    func createRental(customerID: String, vehicleID: String, hours: Int, start: Date, allowBroken: Bool = false) throws {
        guard let c = customer(customerID), !c.isArchived else { throw RentalError.archived }
        guard let v = vehicle(vehicleID) else { throw RentalError.invalid("Vehicle not found.") }
        guard isManager || customerID == currentCustomerID else { throw RentalError.invalid("You can only rent under your own account.") }
        if v.condition == .broken && !allowBroken { throw RentalError.broken }
        try v.markAsRented(allowBroken: allowBroken)
        let due = Calendar.current.date(byAdding: .hour, value: hours, to: start)!
        do {
            let r = try Rental(id: nextRentalID(), customerID: customerID, vehicleID: vehicleID, start: start, due: due,
                               hours: hours, cost: v.calculateRentalCost(forHours: hours))
            rentals.append(r)
        } catch { try? v.markAsAvailable(); throw error }
    }
    func returnRental(_ id: String) throws {
        guard let i = rentals.firstIndex(where: { $0.id == id }) else { throw RentalError.invalid("Rental not found.") }
        var r = rentals[i]
        guard let v = vehicle(r.vehicleID) else { throw RentalError.invalid("Linked vehicle not found.") }
        try r.markReturned(at: Date(), hourlyRate: v.hourlyRate)
        try v.markAsAvailable()
        rentals[i] = r
    }
    func pay(_ id: String) throws {
        guard let i = rentals.firstIndex(where: { $0.id == id }) else { throw RentalError.invalid("Rental not found.") }
        guard isManager || rentals[i].customerID == currentCustomerID else { throw RentalError.invalid("You can only pay your own rentals.") }
        var r = rentals[i]; r.markPaid(); rentals[i] = r
    }
    func available(on date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return activeVehicles.filter { v in
            v.condition != .broken && !rentals.contains { r in
                r.vehicleID == v.id && r.startDate < end && (r.returnedAt ?? r.dueDate) > start
            }
        }.count
    }
    func monthlyIncome(_ date: Date) -> Double {
        rentals.filter { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .month) &&
                         Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .year) }
            .reduce(0) { $0 + $1.totalCost }
    }
    private func nextRentalID() -> String {
        "R\(String(format: "%03d", (rentals.compactMap { Int($0.id.dropFirst()) }.max() ?? 0) + 1))"
    }

    private func seed() {
        do {
            customers = [try Customer(id: "M001", name: "Alex Morgan", phone: "0901 000 001",
                                      email: "manager@swiftwheels.vn", address: "District 1, Ho Chi Minh City", role: .manager)]
            let names = ["Minh Anh", "Gia Huy", "Thanh Vy", "Hoang Nam", "Bao Tran", "Quynh Nhu", "Duc Anh", "Khanh Linh", "Tuan Kiet", "Mai Phuong"]
            for i in 1...19 {
                customers.append(try Customer(id: String(format: "C%03d", i), name: "\(names[(i-1)%10]) \(i)",
                    phone: "090\(String(format: "%07d", i))", email: "customer\(i)@example.com",
                    address: "District \((i%12)+1), Ho Chi Minh City"))
            }
            for i in 1...7 {
                vehicles.append(try Car(id: String(format: "CAR%02d", i), name: ["City","Vios","Civic","Mazda 3","Accent","Corolla","K3"][i-1],
                    manufacturer: ["Honda","Toyota","Honda","Mazda","Hyundai","Toyota","Kia"][i-1],
                    dailyRate: Double(650_000+i*75_000), seats: i.isMultiple(of: 2) ? 5 : 7, serviceCharge: 80_000))
            }
            for i in 1...7 {
                vehicles.append(try Motorcycle(id: String(format: "MOTO%02d", i), name: ["Vision","Air Blade","Winner X","Exciter","SH Mode","Vario","CB150R"][i-1],
                    manufacturer: "Honda", dailyRate: Double(120_000+i*25_000), engineCC: [110,125,150,155,125,160,150][i-1],
                    category: i < 3 ? .small : (i < 6 ? .medium : .large)))
            }
            for i in 1...6 {
                vehicles.append(try ElectricBicycle(id: String(format: "EBIKE%02d", i), name: ["Pega Aura","VinFast Evo","Yadea G5","Giant Momentum","Dat Bike","Asama E-bike"][i-1],
                    manufacturer: ["Pega","VinFast","Yadea","Giant","Dat Bike","Asama"][i-1],
                    dailyRate: Double(90_000+i*15_000), rangeKM: Double(55+i*8), batteryFee: 30_000))
            }
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            for i in 1...100 {
                let v = vehicles[(i*7+i/3) % vehicles.count]
                let c = customers[(i*3) % customers.count]
                let start = cal.date(byAdding: .day, value: -((i*5)%55), to: today)!.addingTimeInterval(Double(i%8)*3600)
                let hours = [3,5,7,10,14,21][i%6]
                let due = cal.date(byAdding: .hour, value: hours, to: start)!
                var r = try Rental(id: String(format: "R%03d", i), customerID: c.id, vehicleID: v.id,
                                   start: start, due: due, hours: hours, cost: v.calculateRentalCost(forHours: hours))
                if i % 9 != 0 { try r.markReturned(at: due.addingTimeInterval(Double(i%3)*1800), hourlyRate: v.hourlyRate) }
                if i % 4 != 0 { r.markPaid() }
                rentals.append(r)
            }
            for v in vehicles where rentals.contains(where: { $0.vehicleID == v.id && $0.status == .active }) {
                try? v.markAsRented(allowBroken: true)
            }
        } catch { assertionFailure("Sample data failed: \(error.localizedDescription)") }
    }
}
