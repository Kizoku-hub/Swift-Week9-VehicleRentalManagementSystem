import SwiftUI

// MARK: - App navigation

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { VehicleListView() }
                .tabItem { Label("Vehicles", systemImage: "car.2.fill") }
            NavigationStack { ManageView() }
                .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
            NavigationStack { RentalInformationView() }
                .tabItem { Label("Rentals", systemImage: "doc.text.magnifyingglass") }
        }
        .tint(.indigo)
    }
}

// MARK: - Reusable Library-style components

struct AccountHeader: View {
    @EnvironmentObject var store: RentalStore
    @State private var showAccount = false
    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(store.isManager ? store.activeCustomers : store.activeCustomers.filter { $0.id == store.currentCustomerID || $0.id == store.managerID }) { c in
                    Button { store.switchAccount(c.id) } label: {
                        if c.id == store.currentCustomerID { Label("\(c.name) · \(c.role.rawValue)", systemImage: "checkmark") }
                        else { Text("\(c.name) · \(c.role.rawValue)") }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: store.isManager ? "person.crop.circle.badge.checkmark" : "person.crop.circle").font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.currentCustomer.name).font(.subheadline.bold())
                        Text("\(store.currentCustomer.role.rawValue) account").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption)
                }
                .padding(11).background(.background, in: RoundedRectangle(cornerRadius: 14))
            }
            Button { showAccount = true } label: {
                Image(systemName: "creditcard.fill").font(.title3).foregroundStyle(.indigo)
                    .frame(width: 48, height: 48).background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            }
            .sheet(isPresented: $showAccount) {
                NavigationStack { CustomerAccountView(customer: store.currentCustomer) }
                    .environmentObject(store)
            }
        }
    }
}
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.13)))
    }
}
struct InfoLine: View {
    let title: String; let value: String
    var body: some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }.font(.subheadline)
    }
}
struct StatusPill: View {
    let text: String; let color: Color
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 6).background(color.opacity(0.12), in: Capsule())
    }
}
struct VehicleRow: View {
    @ObservedObject var vehicle: Vehicle
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: vehicle.symbol).font(.system(size: 29)).foregroundStyle(.indigo)
                .frame(width: 62, height: 62).background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
                Text(vehicle.name).font(.headline)
                Text("\(vehicle.type.rawValue) • \(vehicle.id)").font(.caption).foregroundStyle(.secondary)
                Text(vehicle.manufacturer).font(.caption).foregroundStyle(.secondary)
                Text(money(vehicle.dailyRate) + " / day").font(.caption.bold()).foregroundStyle(.indigo)
            }
            Spacer(minLength: 3)
            VStack(alignment: .trailing, spacing: 5) {
                StatusPill(text: vehicle.availability.rawValue, color: vehicle.availability == .available ? .green : .orange)
                if vehicle.condition != .normal {
                    StatusPill(text: vehicle.condition.rawValue, color: vehicle.condition == .broken ? .red : .orange)
                }
            }
        }.padding(12).background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.14)))
    }
}
func money(_ amount: Double) -> String { "₫\(Int(amount.rounded()).formatted())" }

// MARK: - Vehicles tab

struct VehicleListView: View {
    @EnvironmentObject var store: RentalStore
    @State private var type: VehicleType?
    @State private var search = ""
    @State private var selected: Vehicle?
    var filtered: [Vehicle] {
        store.activeVehicles.filter {
            (type == nil || $0.type == type) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
             $0.id.localizedCaseInsensitiveContains(search) || $0.manufacturer.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                AccountHeader()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find your next ride").font(.largeTitle.bold())
                    Text("Choose a vehicle and start your journey.").foregroundStyle(.secondary)
                }
                SectionCard(title: "Availability · 23–25 Nov 2026") {
                    HStack(spacing: 8) {
                        tile("23 Nov", 23); tile("24 Nov", 24); tile("25 Nov", 25)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        chip("All", type == nil) { type = nil }
                        ForEach(VehicleType.allCases) { t in chip(t.rawValue, type == t) { type = t } }
                    }
                }
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search vehicle, brand, or ID", text: $search)
                }.padding(13).background(.background, in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    Text("Vehicles").font(.title2.bold()); Spacer()
                    Text("\(filtered.count) results").font(.caption).foregroundStyle(.secondary)
                }
                LazyVStack(spacing: 11) {
                    ForEach(filtered) { v in
                        Button { selected = v } label: { VehicleRow(vehicle: v) }.buttonStyle(.plain)
                    }
                }
            }.padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Swift Wheels").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { v in NavigationStack { VehicleDetailView(vehicle: v) }.environmentObject(store) }
    }
    private func tile(_ day: String, _ number: Int) -> some View {
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: number)) ?? Date()
        return VStack(alignment: .leading, spacing: 5) {
            Text(day).font(.caption).foregroundStyle(.secondary)
            Text("\(store.available(on: date))").font(.title2.bold()).foregroundStyle(.indigo)
            Text("available").font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
            .background(Color.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
    private func chip(_ title: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 9)
                .foregroundStyle(active ? .white : .primary)
                .background(active ? Color.indigo : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        }
    }
}

struct VehicleDetailView: View {
    @EnvironmentObject var store: RentalStore
    @ObservedObject var vehicle: Vehicle
    @State private var showBroken = false
    @State private var showRental = false
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: vehicle.symbol).font(.system(size: 58)).foregroundStyle(.indigo)
                        .frame(width: 116, height: 116).background(Color.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 28))
                    Text(vehicle.name).font(.title2.bold())
                    Text("\(vehicle.type.rawValue) · \(vehicle.id)").foregroundStyle(.secondary)
                    Text(money(vehicle.dailyRate) + " / day").font(.title3.bold()).foregroundStyle(.indigo)
                    HStack {
                        StatusPill(text: vehicle.availability.rawValue, color: vehicle.availability == .available ? .green : .orange)
                        StatusPill(text: vehicle.condition.rawValue, color: vehicle.condition == .normal ? .green : .orange)
                    }
                }.frame(maxWidth: .infinity).padding(22).background(.background, in: RoundedRectangle(cornerRadius: 20))
                SectionCard(title: "General Information") {
                    InfoLine(title: "Manufacturer", value: vehicle.manufacturer)
                    InfoLine(title: "Vehicle ID", value: vehicle.id)
                    InfoLine(title: "Hourly rate", value: money(vehicle.hourlyRate))
                    InfoLine(title: "Condition", value: vehicle.condition.rawValue)
                }
                SectionCard(title: "Specifications") {
                    if let x = vehicle as? Car {
                        InfoLine(title: "Seats", value: "\(x.seats)")
                        InfoLine(title: "Service charge", value: money(x.serviceCharge))
                    } else if let x = vehicle as? Motorcycle {
                        InfoLine(title: "Engine", value: "\(x.engineCC)cc")
                        InfoLine(title: "Category", value: x.engineCategory.rawValue)
                    } else if let x = vehicle as? ElectricBicycle {
                        InfoLine(title: "Battery range", value: "\(Int(x.rangeKM)) km")
                        InfoLine(title: "Battery service fee", value: money(x.batteryFee))
                    }
                }
                if vehicle.availability == .available {
                    Button {
                        if vehicle.condition == .broken { showBroken = true } else { showRental = true }
                    } label: {
                        Label("Rent This Vehicle", systemImage: "key.fill").font(.headline)
                            .frame(maxWidth: .infinity).padding(14).foregroundStyle(.white)
                            .background(.indigo, in: RoundedRectangle(cornerRadius: 13))
                    }
                }
            }.padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Vehicle Details").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRental) { RentalCreationView(vehicle: vehicle).environmentObject(store) }
        .alert("Vehicle condition warning", isPresented: $showBroken) {
            Button("Cancel", role: .cancel) {}
            Button("Continue anyway", role: .destructive) { showRental = true }
        } message: {
            Text("This vehicle is marked as broken. Continue only if this is intentional for the simulation.")
        }
    }
}

struct RentalCreationView: View {
    @EnvironmentObject var store: RentalStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    @State private var customerID = ""
    @State private var hours = 7
    @State private var start = Date()
    @State private var message = ""
    @State private var alert = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    LabeledContent("Vehicle", value: vehicle.name)
                    LabeledContent("Hourly rate", value: money(vehicle.hourlyRate))
                }
                Section("Customer") {
                    if store.isManager {
                        Picker("Account", selection: $customerID) {
                            ForEach(store.activeCustomers) { Text($0.name).tag($0.id) }
                        }
                    } else { LabeledContent("Account", value: store.currentCustomer.name) }
                }
                Section("Rental duration") {
                    Stepper("\(hours) hours", value: $hours, in: 1...168)
                    DatePicker("Start time", selection: $start, in: Date()...)
                    LabeledContent("Estimated total", value: money(vehicle.calculateRentalCost(forHours: hours)))
                    Text("One rental day equals 7 billable hours.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Rental").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Confirm", action: create) }
            }
            .onAppear { customerID = store.currentCustomerID }
            .alert("Rental", isPresented: $alert) {
                Button("OK") { if message.contains("successfully") { dismiss() } }
            } message: { Text(message) }
        }
    }
    private func create() {
        do {
            try store.createRental(customerID: store.isManager ? customerID : store.currentCustomerID,
                                   vehicleID: vehicle.id, hours: hours, start: start, allowBroken: vehicle.condition == .broken)
            message = "Rental created successfully."
        } catch { message = error.localizedDescription }
        alert = true
    }
}

// MARK: - Manager screens

struct ManageView: View {
    @EnvironmentObject var store: RentalStore
    @State private var section = "Vehicles"
    @State private var addVehicle = false
    @State private var addCustomer = false
    @State private var editVehicle: Vehicle?
    @State private var editCustomer: Customer?
    @State private var message = ""
    @State private var alert = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                AccountHeader()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Management").font(.largeTitle.bold())
                    Text("Keep the fleet and customer accounts organized.").foregroundStyle(.secondary)
                }
                if store.isManager {
                    SectionCard(title: "This month's income") {
                        Text(money(store.monthlyIncome(Date()))).font(.largeTitle.bold()).foregroundStyle(.indigo)
                        Text("Based on rental records started this month.").font(.caption).foregroundStyle(.secondary)
                    }
                    Picker("Manage", selection: $section) {
                        Text("Vehicles").tag("Vehicles"); Text("Customers").tag("Customers")
                    }.pickerStyle(.segmented)
                    if section == "Vehicles" {
                        ForEach(store.activeVehicles) { v in
                            Button { editVehicle = v } label: { VehicleRow(vehicle: v) }.buttonStyle(.plain)
                                .contextMenu {
                                    Button("Archive Vehicle", role: .destructive) {
                                        do { try store.archiveVehicle(v) } catch { message = error.localizedDescription; alert = true }
                                    }
                                }
                        }
                        Button { addVehicle = true } label: { primaryButton("Register Vehicle", "plus") }
                    } else {
                        ForEach(store.activeCustomers) { c in
                            Button { editCustomer = c } label: {
                                HStack {
                                    Image(systemName: c.isManager ? "person.crop.circle.badge.checkmark" : "person.fill")
                                        .font(.title2).foregroundStyle(.indigo).frame(width: 50, height: 50)
                                        .background(Color.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                                    VStack(alignment: .leading) {
                                        Text(c.name).font(.headline)
                                        Text("\(c.id) · \(c.phone)").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }.padding(12).background(.background, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain)
                                .contextMenu {
                                    if !c.isManager {
                                        Button("Archive Customer", role: .destructive) {
                                            do { try store.archiveCustomer(c) } catch { message = error.localizedDescription; alert = true }
                                        }
                                    }
                                }
                        }
                        Button { addCustomer = true } label: { primaryButton("Register Customer", "person.badge.plus") }
                    }
                } else {
                    SectionCard(title: "Manager access only") {
                        Label("Restricted section", systemImage: "lock.fill").font(.title3)
                        Text("Switch to the Manager account to register, update, or archive vehicles and customers.")
                            .foregroundStyle(.secondary)
                    }
                }
            }.padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Manage").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $addVehicle) { AddVehicleView().environmentObject(store) }
        .sheet(isPresented: $addCustomer) { AddCustomerView().environmentObject(store) }
        .sheet(item: $editVehicle) { v in EditVehicleView(vehicle: v).environmentObject(store) }
        .sheet(item: $editCustomer) { c in CustomerAccountView(customer: c).environmentObject(store) }
        .alert("Management", isPresented: $alert) { Button("OK", role: .cancel) {} } message: { Text(message) }
    }
    private func primaryButton(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon).font(.headline).frame(maxWidth: .infinity).padding(14)
            .foregroundStyle(.white).background(.indigo, in: RoundedRectangle(cornerRadius: 13))
    }
}

struct AddVehicleView: View {
    @EnvironmentObject var store: RentalStore
    @Environment(\.dismiss) var dismiss
    @State private var type: VehicleType = .car
    @State private var id = ""; @State private var name = ""; @State private var maker = ""
    @State private var rate = "700000"; @State private var a = "5"; @State private var b = "80000"
    @State private var message = ""; @State private var alert = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle type") {
                    Picker("Type", selection: $type) {
                        ForEach(VehicleType.allCases) { Text($0.rawValue).tag($0) }
                    }.onChange(of: type) { _, t in
                        switch t { case .car: a = "5"; b = "80000"; case .motorcycle: a = "150"; b = EngineCategory.small.rawValue; case .electricBicycle: a = "70"; b = "30000" }
                    }
                }
                Section("General information") {
                    TextField("Vehicle ID", text: $id); TextField("Name", text: $name); TextField("Manufacturer", text: $maker)
                    TextField("Daily rate (VND)", text: $rate).keyboardType(.decimalPad)
                }
                Section("Specifications") {
                    TextField(type == .car ? "Seats" : type == .motorcycle ? "Engine cc" : "Battery range km", text: $a).keyboardType(.decimalPad)
                    if type == .motorcycle {
                        Picker("Engine category", selection: $b) { ForEach(EngineCategory.allCases) { Text($0.rawValue).tag($0.rawValue) } }
                    } else {
                        TextField(type == .car ? "Service charge" : "Battery service fee", text: $b).keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Register Vehicle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
            }
            .alert("Vehicle", isPresented: $alert) { Button("OK") { if message.contains("successfully") { dismiss() } } } message: { Text(message) }
        }
    }
    private func save() {
        guard let r = Double(rate) else { message = "Enter a valid daily rate."; alert = true; return }
        do { try store.addVehicle(type: type, id: id, name: name, maker: maker, rate: r, a: a, b: b); message = "Vehicle registered successfully." }
        catch { message = error.localizedDescription }
        alert = true
    }
}

struct EditVehicleView: View {
    @EnvironmentObject var store: RentalStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    @State private var name = ""; @State private var maker = ""; @State private var rate = ""
    @State private var condition: VehicleCondition = .normal; @State private var a = ""; @State private var b = ""
    @State private var message = ""; @State private var alert = false
    var body: some View {
        Form {
            Section("General information") {
                TextField("Name", text: $name); TextField("Manufacturer", text: $maker)
                TextField("Daily rate", text: $rate).keyboardType(.decimalPad)
                Picker("Condition", selection: $condition) { ForEach(VehicleCondition.allCases) { Text($0.rawValue).tag($0) } }
            }
            Section("Specifications") {
                TextField(vehicle is Car ? "Seats" : vehicle is Motorcycle ? "Engine cc" : "Battery range km", text: $a)
                if vehicle is Motorcycle {
                    Picker("Engine category", selection: $b) { ForEach(EngineCategory.allCases) { Text($0.rawValue).tag($0.rawValue) } }
                } else {
                    TextField(vehicle is Car ? "Service charge" : "Battery service fee", text: $b).keyboardType(.decimalPad)
                }
            }
            Section {
                Button("Save Changes", action: save).frame(maxWidth: .infinity)
                if vehicle.availability == .available {
                    Button("Archive Vehicle", role: .destructive) {
                        do { try store.archiveVehicle(vehicle); dismiss() } catch { message = error.localizedDescription; alert = true }
                    }
                }
            }
        }
        .navigationTitle("Update Vehicle").onAppear(perform: load)
        .alert("Vehicle", isPresented: $alert) { Button("OK") { if message.contains("successfully") { dismiss() } } } message: { Text(message) }
    }
    private func load() {
        name = vehicle.name; maker = vehicle.manufacturer; rate = "\(vehicle.dailyRate)"; condition = vehicle.condition
        if let x = vehicle as? Car { a = "\(x.seats)"; b = "\(x.serviceCharge)" }
        else if let x = vehicle as? Motorcycle { a = "\(x.engineCC)"; b = x.engineCategory.rawValue }
        else if let x = vehicle as? ElectricBicycle { a = "\(x.rangeKM)"; b = "\(x.batteryFee)" }
    }
    private func save() {
        guard let r = Double(rate) else { message = "Enter a valid daily rate."; alert = true; return }
        do { try store.updateVehicle(vehicle, name: name, maker: maker, rate: r, condition: condition, a: a, b: b); message = "Vehicle updated successfully." }
        catch { message = error.localizedDescription }
        alert = true
    }
}

struct AddCustomerView: View {
    @EnvironmentObject var store: RentalStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""; @State private var phone = ""; @State private var email = ""; @State private var address = ""
    @State private var message = ""; @State private var alert = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Customer information") {
                    TextField("Full name", text: $name); TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress); TextField("Address", text: $address)
                }
            }.navigationTitle("Register Customer")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
                }
                .alert("Customer", isPresented: $alert) { Button("OK") { if message.contains("successfully") { dismiss() } } } message: { Text(message) }
        }
    }
    private func save() {
        do { try store.addCustomer(name: name, phone: phone, email: email, address: address); message = "Customer registered successfully." }
        catch { message = error.localizedDescription }
        alert = true
    }
}

// MARK: - Customer profile / payment

struct CustomerAccountView: View {
    @EnvironmentObject var store: RentalStore
    @ObservedObject var customer: Customer
    @State private var name = ""; @State private var phone = ""; @State private var email = ""; @State private var address = ""
    @State private var message = ""; @State private var alert = false
    var records: [Rental] { store.rentals(customer: customer.id) }
    var unpaid: Double { records.filter { $0.paymentStatus == .unpaid }.reduce(0) { $0 + $1.totalCost } }
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 8) {
                    Image(systemName: customer.isManager ? "person.crop.circle.badge.checkmark" : "person.crop.circle.fill")
                        .font(.system(size: 54)).foregroundStyle(.indigo)
                    Text(customer.name).font(.title2.bold())
                    Text("\(customer.role.rawValue) · \(customer.id)").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).padding(20).background(.background, in: RoundedRectangle(cornerRadius: 18))
                SectionCard(title: "Contact Information") {
                    TextField("Full name", text: $name); TextField("Phone", text: $phone)
                    TextField("Email", text: $email); TextField("Address", text: $address)
                    Button("Save Contact Information", action: save).buttonStyle(.borderedProminent)
                }
                SectionCard(title: "Payment Summary") {
                    InfoLine(title: "Rental records", value: "\(records.count)")
                    InfoLine(title: "Outstanding amount", value: money(unpaid))
                }
                SectionCard(title: "Rental History") {
                    if records.isEmpty { Text("No rental records yet.").foregroundStyle(.secondary) }
                    ForEach(records) { RentalCard(rental: $0) }
                }
            }.padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Customer Account").navigationBarTitleDisplayMode(.inline)
        .onAppear { name = customer.name; phone = customer.phone; email = customer.email; address = customer.address }
        .alert("Customer Account", isPresented: $alert) { Button("OK", role: .cancel) {} } message: { Text(message) }
    }
    private func save() {
        do { try store.updateCustomer(customer, name: name, phone: phone, email: email, address: address); message = "Contact information updated." }
        catch { message = error.localizedDescription }
        alert = true
    }
}

// MARK: - Rental information tab

struct RentalInformationView: View {
    @EnvironmentObject var store: RentalStore
    @State private var mode = "Customer"
    @State private var customerID = ""
    @State private var vehicleID = ""
    var records: [Rental] {
        let result = mode == "Customer" ? (customerID.isEmpty ? [] : store.rentals(customer: customerID))
                                        : (vehicleID.isEmpty ? [] : store.rentals(vehicle: vehicleID))
        return store.isManager ? result : result.filter { $0.customerID == store.currentCustomerID }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AccountHeader()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rental Records").font(.largeTitle.bold())
                    Text("Look up a customer's or vehicle's transaction history.").foregroundStyle(.secondary)
                }
                SectionCard(title: "Find records") {
                    Picker("Search by", selection: $mode) {
                        Text("Customer").tag("Customer"); Text("Vehicle").tag("Vehicle")
                    }.pickerStyle(.segmented)
                    if mode == "Customer" {
                        Picker("Choose customer", selection: $customerID) {
                            Text("Select a customer").tag("")
                            ForEach(store.isManager ? store.activeCustomers : [store.currentCustomer]) { Text($0.name).tag($0.id) }
                        }
                    } else {
                        Picker("Choose vehicle", selection: $vehicleID) {
                            Text("Select a vehicle").tag("")
                            ForEach(store.activeVehicles) { Text("\($0.name) · \($0.id)").tag($0.id) }
                        }
                    }
                }
                HStack { Text("Matching rentals").font(.title2.bold()); Spacer(); Text("\(records.count) records").font(.caption).foregroundStyle(.secondary) }
                if records.isEmpty {
                    ContentUnavailableView("No rental records", systemImage: "doc.text.magnifyingglass",
                                           description: Text("Choose a customer or vehicle to see matching records."))
                } else {
                    ForEach(records) { RentalCard(rental: $0) }
                }
            }.padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Rental Information").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if customerID.isEmpty { customerID = store.currentCustomerID }
            if vehicleID.isEmpty { vehicleID = store.activeVehicles.first?.id ?? "" }
        }
        .onChange(of: store.currentCustomerID) { _, newID in if !store.isManager { customerID = newID } }
    }
}

struct RentalCard: View {
    @EnvironmentObject var store: RentalStore
    let rental: Rental
    @State private var message = ""; @State private var alert = false
    var body: some View {
        SectionCard(title: "\(store.vehicle(rental.vehicleID)?.name ?? "Archived vehicle") · \(rental.id)") {
            InfoLine(title: "Customer", value: store.customer(rental.customerID)?.name ?? "Archived customer")
            InfoLine(title: "Vehicle ID", value: rental.vehicleID)
            InfoLine(title: "Start", value: rental.startDate.formatted(date: .abbreviated, time: .shortened))
            InfoLine(title: "Agreed return", value: rental.dueDate.formatted(date: .abbreviated, time: .shortened))
            if let returned = rental.returnedAt { InfoLine(title: "Actual return", value: returned.formatted(date: .abbreviated, time: .shortened)) }
            InfoLine(title: "Duration", value: "\(rental.hours) hours")
            InfoLine(title: "Status", value: rental.status.rawValue)
            InfoLine(title: "Payment", value: rental.paymentStatus.rawValue)
            InfoLine(title: "Total cost", value: money(rental.totalCost))
            if rental.status == .active && store.isManager {
                Button("Record Vehicle Return") {
                    do { try store.returnRental(rental.id); message = "Vehicle returned successfully." }
                    catch { message = error.localizedDescription }
                    alert = true
                }.buttonStyle(.borderedProminent).tint(.orange)
            }
            if rental.paymentStatus == .unpaid && (store.isManager || rental.customerID == store.currentCustomerID) {
                Button("Pay / Mark as Paid") {
                    do { try store.pay(rental.id); message = "Payment marked as paid." }
                    catch { message = error.localizedDescription }
                    alert = true
                }.buttonStyle(.borderedProminent)
            }
        }.alert("Rental", isPresented: $alert) { Button("OK", role: .cancel) {} } message: { Text(message) }
    }
}
