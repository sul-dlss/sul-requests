# frozen_string_literal: true

module Home
  module CardView
    class SummaryCardComponentPreview < ViewComponent::Preview
      layout 'lookbook'

      def saved_for_later_empty
        render Home::SummaryCardComponent.new(
          title: 'Saved for later',
          icon: 'bi-pin-angle-fill',
          count: 0,
          item_label: 'item',
          empty_label: 'No saved items',
          path: '#'
        )
      end

      def saved_for_later_with_items
        render Home::SummaryCardComponent.new(
          title: 'Saved for later',
          icon: 'bi-pin-angle-fill',
          count: 3,
          item_label: 'item',
          empty_label: 'No saved items',
          status: '<span class="text-digital-red-dark">Requests not complete</span>'.html_safe,
          path: '#'
        )
      end

      def borrowed_items_empty
        render Home::SummaryCardComponent.new(
          title: 'Borrowed items',
          icon: 'bi-book',
          count: 0,
          item_label: 'item',
          item_label_suffix: 'currently loaned',
          empty_label: 'No items on loan',
          path: '#'
        )
      end

      def borrowed_items_with_status
        render Home::SummaryCardComponent.new(
          title: 'Borrowed items',
          icon: 'bi-book',
          count: 5,
          item_label: 'item',
          item_label_suffix: 'currently loaned',
          empty_label: 'No items on loan',
          status: '<span class="text-digital-red-dark"><span class="fw-semibold">2</span> due soon</span>'.html_safe,
          path: '#'
        )
      end

      def pickup_requests_empty
        render Home::SummaryCardComponent.new(
          title: 'Pickup requests',
          icon: 'bi-bag',
          count: 0,
          item_label: 'item',
          item_label_suffix: 'requested',
          empty_label: 'No pickup requests',
          path: '#'
        )
      end

      def pickup_requests_with_status
        render Home::SummaryCardComponent.new(
          title: 'Pickup requests',
          icon: 'bi-bag',
          count: 4,
          item_label: 'item',
          item_label_suffix: 'requested',
          empty_label: 'No pickup requests',
          status: '<span class="text-digital-red-dark"><span class="fw-semibold">2</span> items ready for pickup</span>'.html_safe,
          path: '#'
        )
      end

      def digitization_requests_empty
        render Home::SummaryCardComponent.new(
          title: 'Digitization requests',
          icon: 'bi-printer',
          count: 0,
          item_label: 'item',
          item_label_suffix: 'requested',
          empty_label: 'No digitization requests',
          path: '#',
          empty_path: '#',
          empty_link_label: 'View past requests'
        )
      end

      def digitization_requests_with_status # rubocop:disable Metrics/MethodLength
        render Home::SummaryCardComponent.new(
          title: 'Digitization requests',
          icon: 'bi-printer',
          count: 3,
          item_label: 'item',
          item_label_suffix: 'requested',
          empty_label: 'No digitization requests',
          path: '#',
          empty_path: '#',
          empty_link_label: 'View past requests',
          status: '<span class="text-digital-red-dark"><span class="fw-semibold">2</span> delivered recently via email</span>'.html_safe
        )
      end

      # No activity is upcoming, so the card sends the user to the past ones.
      def activities_empty
        render activities_card(in_progress: 0, upcoming: 0, link_label: 'View past activities')
      end

      # One activity, still to start. The card reports the date it starts.
      def activities_with_next_up
        render activities_card(in_progress: 0, upcoming: 1) do |c|
          c.with_status_next_up(date: Date.new(2026, 6, 18))
        end
      end

      # One activity, already started. Nothing is waiting to start, so no date shows.
      def activities_in_progress
        render activities_card(in_progress: 1, upcoming: 0)
      end

      # One activity in progress and one still to start. The body counts both kinds.
      # The date belongs to the one still to start.
      def activities_in_progress_with_another_upcoming
        render activities_card(in_progress: 1, upcoming: 1) do |c|
          c.with_status_next_up(date: Date.new(2026, 6, 18))
        end
      end

      def appointments_empty
        render Home::SummaryCardComponent.new(
          title: 'Reading room appointments',
          icon: 'bi-calendar',
          count: 0,
          item_label: 'appointment',
          empty_label: 'No appointments scheduled',
          path: '#',
          empty_path: '#',
          empty_link_label: 'View past appointments'
        )
      end

      def appointments_with_next_up # rubocop:disable Metrics/MethodLength
        render Home::SummaryCardComponent.new(
          title: 'Reading room appointments',
          icon: 'bi-calendar',
          count: 2,
          item_label: 'appointment',
          empty_label: 'No appointments scheduled',
          path: '#',
          empty_path: '#',
          empty_link_label: 'View past appointments',
          secondary_count: 5,
          secondary_label: 'item',
          secondary_label_suffix: 'scheduled',
          next_up_date: Date.new(2026, 6, 18)
        )
      end

      private

      def activities_card(in_progress:, upcoming:, link_label: nil)
        Home::SummaryCardComponent.new(
          id: 'aeon-activities',
          title: 'Activities',
          icon_class: 'bi-person-video3',
          label: ApplicationController.helpers.activities_card_label(in_progress:, upcoming:),
          path: '#',
          link_label:
        )
      end
    end
  end
end
