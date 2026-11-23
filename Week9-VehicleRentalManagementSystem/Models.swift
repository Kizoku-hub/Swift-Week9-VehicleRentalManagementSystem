import Foundation
import Combine

enum VehicleType: String, CaseIterable, Identifiable {
    case car = "Car", motorcycle = "Motorcycle", electricBicycle = "Electric Bicycle"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .car: "car.fill"; case .motorcycle: "motorcycle"; case .electricBicycle: "bicycle" }
    }
}
enum VehicleAvailability: String { case available = "Available", rented = "Rented" }
enum VehicleCondition: String, CaseIterable, Identifiable {
    case normal = "Normal", maintenance = "Needs Maintenance", broken = "Broken"
    var id: String { rawValue }
}
enum UserRole: String { case manager = "Manager", customer = "Customer" }
enum RentalStatus: String { case active = "Active", returned = "Returned" }
enum PaymentStatus: String { case unpaid = "Unpaid", paid = "Paid" }
enum EngineCategory: String, CaseIterable, Identifiable {
    case small = "Under 150cc", medium = "150cc–400cc", large = "Over 400cc"
    var id: String { rawValue }
    var dailyExtra: Double { switch self { case .small: 0; case .medium: 50_000; case .large: 100_000 } }
}
enum RentalError: LocalizedError {
    case invalid(String), unavailable, broken, archived, returned, invalidDate
    var errorDescription: String? {
        switch self {
        case .invalid(let s): s
        case .unavailable: "This vehicle is currently rented."
        case .broken: "This vehicle is marked as broken. A second confirmation is required."
        case .archived: "Archived records cannot be used for new rentals."
        case .returned: "This rental has already been returned."
        case .invalidDate: "The return date cannot be earlier than the rental start date."
        }
    }
}

// Parent class. The subclasses override pricing, demonstrating polymorphism.
class Vehicle: ObservableObject, Identifiable {
    let id: String
    @Published private(set) var name: String
    @Published private(set) var manufacturer: String
    @Published private(set) var dailyRate: Double
    @Published private(set) var availability: VehicleAvailability = .available
    @Published private(set) var condition: VehicleCondition = .normal
    @Published private(set) var isArchived = false
    var type: VehicleType { fatalError("Override type in subclass.") }
    var symbol: String { type.symbol }
    var hourlyRate: Double { dailyRate / 7 }

    init(id: String, name: String, manufacturer: String, dailyRate: Double) throws {
        let cleanID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMaker = manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty, !cleanName.isEmpty, !cleanMaker.isEmpty else {
            throw RentalError.invalid("ID, name, and manufacturer are required.")
        }
        guard dailyRate > 0 else { throw RentalError.invalid("Daily rate must be greater than zero.") }
        self.id = cleanID; self.name = cleanName; self.manufacturer = cleanMaker; self.dailyRate = dailyRate
    }
    func calculateRentalCost(forHours hours: Int) -> Double {
        guard hours > 0 else { return 0 }; return hourlyRate * Double(hours)
    }
    func updateGeneralInfo(name: String, manufacturer: String, dailyRate: Double) throws {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !m.isEmpty, dailyRate > 0 else { throw RentalError.invalid("Enter valid vehicle information and a positive daily rate.") }
        self.name = n; self.manufacturer = m; self.dailyRate = dailyRate
    }
    func updateCondition(_ value: VehicleCondition) { condition = value }
    func archive() { isArchived = true }
    func markAsRented(allowBroken: Bool) throws {
        guard !isArchived else { throw RentalError.archived }
        guard availability == .available else { throw RentalError.unavailable }
        if condition == .broken && !allowBroken { throw RentalError.broken }
        availability = .rented
    }
    func markAsAvailable() throws {
        guard availability == .rented else { throw RentalError.invalid("Vehicle is not rented.") }
        availability = .available
    }
}
final class Car: Vehicle {
    @Published private(set) var seats: Int
    @Published private(set) var serviceCharge: Double
    override var type: VehicleType { .car }
    init(id: String, name: String, manufacturer: String, dailyRate: Double, seats: Int, serviceCharge: Double) throws {
        guard seats > 0, serviceCharge >= 0 else { throw RentalError.invalid("Invalid car specifications.") }
        self.seats = seats; self.serviceCharge = serviceCharge
        try super.init(id: id, name: name, manufacturer: manufacturer, dailyRate: dailyRate)
    }
    override func calculateRentalCost(forHours hours: Int) -> Double {
        hours > 0 ? super.calculateRentalCost(forHours: hours) + serviceCharge : 0
    }
    func updateSpecs(seats: Int, fee: Double) throws {
        guard seats > 0, fee >= 0 else { throw RentalError.invalid("Invalid car specifications.") }
        self.seats = seats; serviceCharge = fee
    }
}
final class Motorcycle: Vehicle {
    @Published private(set) var engineCC: Int
    @Published private(set) var engineCategory: EngineCategory
    override var type: VehicleType { .motorcycle }
    init(id: String, name: String, manufacturer: String, dailyRate: Double, engineCC: Int, category: EngineCategory) throws {
        guard engineCC > 0 else { throw RentalError.invalid("Engine capacity must be positive.") }
        self.engineCC = engineCC; engineCategory = category
        try super.init(id: id, name: name, manufacturer: manufacturer, dailyRate: dailyRate)
    }
    override func calculateRentalCost(forHours hours: Int) -> Double {
        hours > 0 ? super.calculateRentalCost(forHours: hours) + engineCategory.dailyExtra * Double(hours) / 7 : 0
    }
    func updateSpecs(cc: Int, category: EngineCategory) throws {
        guard cc > 0 else { throw RentalError.invalid("Engine capacity must be positive.") }
        engineCC = cc; engineCategory = category
    }
}
final class ElectricBicycle: Vehicle {
    @Published private(set) var rangeKM: Double
    @Published private(set) var batteryFee: Double
    override var type: VehicleType { .electricBicycle }
    init(id: String, name: String, manufacturer: String, dailyRate: Double, rangeKM: Double, batteryFee: Double) throws {
        guard rangeKM > 0, batteryFee >= 0 else { throw RentalError.invalid("Invalid e-bike specifications.") }
        self.rangeKM = rangeKM; self.batteryFee = batteryFee
        try super.init(id: id, name: name, manufacturer: manufacturer, dailyRate: dailyRate)
    }
    override func calculateRentalCost(forHours hours: Int) -> Double {
        hours > 0 ? super.calculateRentalCost(forHours: hours) + batteryFee : 0
    }
    func updateSpecs(range: Double, fee: Double) throws {
        guard range > 0, fee >= 0 else { throw RentalError.invalid("Invalid e-bike specifications.") }
        rangeKM = range; batteryFee = fee
    }
}

final class Customer: ObservableObject, Identifiable {
    let id: String
    @Published private(set) var name: String
    @Published private(set) var phone: String
    @Published private(set) var email: String
    @Published private(set) var address: String
    @Published private(set) var role: UserRole
    @Published private(set) var isArchived = false
    var isManager: Bool { role == .manager }
    init(id: String, name: String, phone: String, email: String, address: String, role: UserRole = .customer) throws {
        let cleanID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty, !cleanName.isEmpty else { throw RentalError.invalid("Customer ID and name are required.") }
        self.id = cleanID; self.name = cleanName; self.phone = phone; self.email = email; self.address = address; self.role = role
    }
    func updateContact(name: String, phone: String, email: String, address: String) throws {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { throw RentalError.invalid("Customer name is required.") }
        self.name = n; self.phone = phone; self.email = email; self.address = address
    }
    func archive() { isArchived = true }
}

// A transaction links records by IDs; it does not duplicate Customer or Vehicle objects.
struct Rental: Identifiable {
    let id: String
    let customerID: String
    let vehicleID: String
    let startDate: Date
    let dueDate: Date
    let hours: Int
    let baseCost: Double
    private(set) var returnedAt: Date?
    private(set) var lateFee = 0.0
    private(set) var paymentStatus: PaymentStatus = .unpaid
    var status: RentalStatus { returnedAt == nil ? .active : .returned }
    var totalCost: Double { baseCost + lateFee }

    init(id: String, customerID: String, vehicleID: String, start: Date, due: Date, hours: Int, cost: Double) throws {
        guard hours > 0, due > start, cost >= 0 else { throw RentalError.invalid("Invalid rental duration, deadline, or price.") }
        self.id = id; self.customerID = customerID; self.vehicleID = vehicleID
        startDate = start; dueDate = due; self.hours = hours; baseCost = cost
    }
    mutating func markReturned(at date: Date, hourlyRate: Double) throws {
        guard returnedAt == nil else { throw RentalError.returned }
        guard date >= startDate else { throw RentalError.invalidDate }
        let lateHours = max(0, date.timeIntervalSince(dueDate) / 3600)
        lateFee = 1.5 * hourlyRate * lateHours
        returnedAt = date
    }
    mutating func markPaid() { paymentStatus = .paid }
}
