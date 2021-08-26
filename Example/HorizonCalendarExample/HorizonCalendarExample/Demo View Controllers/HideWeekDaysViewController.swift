import HorizonCalendar
import UIKit

final class HideWeekDaysViewController: DemoViewController {

  // MARK: Internal

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Day Range Selection"

    calendarView.daySelectionHandler = { [weak self] day in
      guard let self = self else { return }

      switch self.calendarSelection {
      case .singleDay(let selectedDay):
        if day > selectedDay {
          self.calendarSelection = .dayRange(selectedDay...day)
        } else {
          self.calendarSelection = .singleDay(day)
        }
      case .none, .dayRange:
        self.calendarSelection = .singleDay(day)
      }

      self.calendarView.setContent(self.makeContent())

      if
        UIAccessibility.isVoiceOverRunning,
        let selectedDate = self.calendar.date(from: day.components)
      {
        self.calendarView.layoutIfNeeded()
        let accessibilityElementToFocus = self.calendarView.accessibilityElementForVisibleDate(
          selectedDate)
        UIAccessibility.post(notification: .screenChanged, argument: accessibilityElementToFocus)
      }
    }
  }

  override func makeContent() -> CalendarViewContent {
    let startDate = calendar.date(from: DateComponents(year: 2020, month: 01, day: 01))!
    let endDate = calendar.date(from: DateComponents(year: 2021, month: 12, day: 31))!

    let calendarSelection = self.calendarSelection
    let dateRanges: Set<ClosedRange<Date>>
    if
      case .dayRange(let dayRange) = calendarSelection,
      let lowerBound = calendar.date(from: dayRange.lowerBound.components),
      let upperBound = calendar.date(from: dayRange.upperBound.components)
    {
      dateRanges = [lowerBound...upperBound]
    } else {
      dateRanges = []
    }

    return CalendarViewContent(
      calendar: calendar,
      visibleDateRange: startDate...endDate,
      monthsLayout: .vertical(options: .init(daysOfWeekOptions: .hide)))

      .withInterMonthSpacing(24)
      .withVerticalDayMargin(8)
      .withHorizontalDayMargin(8)

      .withDayItemModelProvider { [weak self] day in
        let textColor: UIColor
        if #available(iOS 13.0, *) {
          textColor = .label
        } else {
          textColor = .black
        }

        let isSelectedStyle: Bool
        switch calendarSelection {
        case .singleDay(let selectedDay):
          isSelectedStyle = day == selectedDay
        case .dayRange(let selectedDayRange):
          isSelectedStyle = day == selectedDayRange.lowerBound || day == selectedDayRange.upperBound
        case .none:
          isSelectedStyle = false
        }

        let dayAccessibilityText: String?
        if let date = self?.calendar.date(from: day.components) {
          dayAccessibilityText = self?.dayDateFormatter.string(from: date)
        } else {
          dayAccessibilityText = nil
        }

        return CalendarItemModel<DayView>(
          invariantViewProperties: .init(textColor: textColor, isSelectedStyle: isSelectedStyle),
          viewModel: .init(dayText: "\(day.day)", dayAccessibilityText: dayAccessibilityText))
      }

      .withDayRangeItemModelProvider(for: dateRanges) { dayRangeLayoutContext in
        CalendarItemModel<DayRangeIndicatorView>(
          invariantViewProperties: .init(),
          viewModel: .init(
            framesOfDaysToHighlight: dayRangeLayoutContext.daysAndFrames.map { $0.frame }))
      }
  }

  // MARK: Private

  private enum CalendarSelection {
    case singleDay(Day)
    case dayRange(DayRange)
  }
  private var calendarSelection: CalendarSelection?

}
