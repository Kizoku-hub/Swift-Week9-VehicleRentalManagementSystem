# Swift Wheels — Vehicle Rental Management System

## Open and run
1. Unzip this project.
2. Open `Midterm-2026-2027/Midterm-2026-2027.xcodeproj` in Xcode.
3. Select an iPhone simulator running iOS 17 or later.
4. Press `Command + B` to build, then `Command + R` to run.

This project is based on your supplied Library Equipment Xcode project. It keeps the project settings
and asset catalog, and adapts the visual style: indigo accent, system grouped background, wide
rounded white cards, category capsule filters, and simple bottom tabs.

## Demo accounts
- Manager: `M001` — Alex Morgan (selected by default).
- Customers: `C001` through `C019`.
Use the account selector at the top of each main tab to switch accounts.

## Included
- 20 vehicles: 7 cars, 7 motorcycles, 6 electric bicycles.
- 20 customer accounts: 1 manager + 19 customers.
- 100 sample rental transactions.
- Vehicle browse, details, type filters, and search.
- Manager-only vehicle/customer registration, updates, and archive.
- Customer contact details, own rental history, and payment simulation.
- Rental lookup by selecting a customer or vehicle from existing lists.
- Rental creation, vehicle return, late fees, and payment status.
- Availability overview for 23, 24, and 25 November 2026.
- Monthly income statistic.
- Broken-vehicle warning with a second confirmation.
- Archive rather than permanent deletion, preserving linked rental history.

## Business rules
- 7 billable hours = 1 rental day; hourly rate = daily rate / 7.
- Car: base rental cost + one service charge per rental.
- Motorcycle: base cost + engine-category surcharge proportional to hours / 7.
- E-bike: base rental cost + one battery service fee per rental.
- Late fee = 1.5 × hourly rate × late hours.
- Manager is a `Customer` object with role `.manager`, not a subclass.
- Rental records connect to customers and vehicles through IDs.
- Vehicle availability and physical condition are separate concepts.
- Payment is simulated (Unpaid → Paid); no real payment gateway is connected.

## Source files
- `Models.swift`: enums, Vehicle inheritance hierarchy, Customer, Rental.
- `RentalStore.swift`: shared state, validation, business operations, and sample data.
- `ContentView.swift`: tabs and all screens/reusable SwiftUI components.
- `Midterm_2026_2027App.swift`: app entry point and shared store injection.

## Simulation limitation
Sample data is generated in memory when the app launches. It is not persisted after the app closes.
