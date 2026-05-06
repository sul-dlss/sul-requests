# frozen_string_literal: true

require 'rails_helper'

# Tests keyboard/focus behaviour of the custom Stimulus date picker.
# Uses Lookbook previews as test pages so these run independently of
# the appointment form (which uses the native date field today).
RSpec.describe 'Date picker keyboard navigation', :js do
  # Today is the initial focusedDate (min = today, no reading room in the preview).
  let(:today) { Time.zone.today }

  # TODO: change to actual path after we move this out of Lookbook
  before { visit '/lookbook/preview/aeon/appointment_date_picker/default' }

  def open_picker
    find('[data-date-picker-target="display"]').click
    expect(page).to have_css('[data-date-picker-target="grid"] button[tabindex="0"]', visible: :all)
  end

  # Send a key to whichever grid button currently holds tabindex=0
  def grid_send(*keys)
    find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(*keys)
  end

  def focused_date
    page.evaluate_script('document.activeElement.dataset.date')
  end

  describe 'on open' do
    it 'focuses today in the grid' do
      open_picker
      expect(focused_date).to eq(today.iso8601)
    end
  end

  describe 'Escape key' do
    it 'closes the picker and returns focus to the display button' do
      open_picker
      grid_send(:escape)
      expect(page).to have_css('[data-date-picker-target="calendar"][hidden]', visible: :all)
      display_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"display\"]')"
      )
      expect(display_focused).to be true
    end
  end

  describe 'Tab key focus trap' do
    it 'Tab from the focused day moves to the Previous month button' do
      open_picker
      grid_send(:tab)
      prev_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"prevBtn\"]')"
      )
      expect(prev_focused).to be true
    end

    it 'natural Tab from Previous month moves to Next month' do
      open_picker
      grid_send(:tab) # prevBtn
      find('[data-date-picker-target="prevBtn"]').send_keys(:tab) # nextBtn (natural DOM order)
      next_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"nextBtn\"]')"
      )
      expect(next_focused).to be true
    end

    it 'Shift+Tab from Previous month wraps back to the focused day' do
      open_picker
      grid_send(:tab) # prevBtn
      find('[data-date-picker-target="prevBtn"]').send_keys([:shift, :tab])
      day_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"grid\"] button[tabindex=\"0\"]')"
      )
      expect(day_focused).to be true
    end
  end

  describe 'arrow key navigation' do
    it 'ArrowRight moves forward one day' do
      open_picker
      grid_send(:arrow_right)
      expect(focused_date).to eq((today + 1).iso8601)
    end

    it 'ArrowLeft moves back one day' do
      open_picker
      grid_send(:arrow_right)
      find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(:arrow_left)
      expect(focused_date).to eq(today.iso8601)
    end

    it 'ArrowDown moves forward one week' do
      open_picker
      grid_send(:arrow_down)
      expect(focused_date).to eq((today + 7).iso8601)
    end

    it 'ArrowUp moves back one week' do
      open_picker
      grid_send(:arrow_down)
      find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(:arrow_up)
      expect(focused_date).to eq(today.iso8601)
    end
  end

  describe 'month wrapping' do
    it 'ArrowRight on the last day of the month advances to the next month' do
      open_picker
      last_day = Date.new(today.year, today.month, -1)
      days_to_last = (last_day - today).to_i

      # Navigate to the last day of the month using ArrowDown (weeks) then ArrowRight (days).
      (days_to_last / 7).times { grid_send(:arrow_down) }
      (days_to_last % 7).times { grid_send(:arrow_right) }
      expect(focused_date).to eq(last_day.iso8601)

      # One more ArrowRight wraps into the next month.
      grid_send(:arrow_right)
      first_of_next = (last_day + 1).iso8601
      expect(focused_date).to eq(first_of_next)
      next_month_label = Date.parse(first_of_next).strftime('%-B %Y')
      expect(page).to have_text(next_month_label)
    end

    it 'ArrowLeft on the first day of the month goes back to the previous month' do
      open_picker
      # Click Next month — focusedDate (today) is outside the new month,
      # so the fallback sets tabindex=0 on the first available day of that month.
      find('[data-date-picker-target="nextBtn"]').click

      first_of_next_month = Date.new(today.year, today.month, -1) + 1
      expect(page).to have_text(first_of_next_month.strftime('%-B %Y'))

      # Arrow left from the first day of that month → last day of this month.
      find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(:arrow_left)
      last_day = Date.new(today.year, today.month, -1).iso8601
      expect(focused_date).to eq(last_day)
      expect(page).to have_text(today.strftime('%-B %Y'))
    end
  end

  describe 'legend' do
    it 'is hidden (but present) when there are no marked days' do
      open_picker
      legend = find('[data-date-picker-target="legend"]', visible: :all)
      expect(legend).to be_present
      expect(legend[:style]).to include('visibility: hidden')
    end

    context 'with marked days' do
      before { visit '/lookbook/preview/aeon/appointment_date_picker/with_marked_days' }

      it 'is visible when the current month has marked days' do
        open_picker
        legend = find('[data-date-picker-target="legend"]', visible: :all)
        expect(legend[:style]).to include('visibility: visible')
        expect(legend).to have_text('Existing appointment')
      end

      it 'hides when navigating to a month with no marked days' do
        open_picker
        # Navigate far enough forward that no marked dates fall in that month.
        # Marked dates are today+2..today+14, all within this month or next at most;
        # going 3 months ahead guarantees none.
        3.times { find('[data-date-picker-target="nextBtn"]').click }
        legend = find('[data-date-picker-target="legend"]', visible: :all)
        expect(legend[:style]).to include('visibility: hidden')
      end
    end
  end

  describe 'skipping disabled dates' do
    # Use the with_disabled_days preview which disables today+2 and a range later in the month.
    before { visit '/lookbook/preview/aeon/appointment_date_picker/with_disabled_days' }

    it 'ArrowRight skips a disabled date and lands on the next enabled date' do
      open_picker
      # today+2 is always disabled in this preview. Navigate from today+1 to confirm it jumps to today+3.
      grid_send(:arrow_right) # today → today+1
      find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(:arrow_right)
      # today+2 is disabled, so focus should land on today+3
      expect(focused_date).to eq((today + 3).iso8601)
    end
  end
end
