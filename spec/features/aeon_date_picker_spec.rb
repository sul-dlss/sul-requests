# frozen_string_literal: true

require 'rails_helper'

# Tests keyboard/focus behaviour of the custom Stimulus date picker.
# TODO: use real form paths once this graduates from Lookbook previews
RSpec.describe 'Date picker keyboard navigation', :js do
  # Today is the initial focusedDate (min = today, no reading room in the preview).
  let(:today) { Time.zone.today }

  before { visit '/lookbook/preview/date_picker/default' }

  def open_picker
    find('[data-date-picker-target="button"]').click
    expect(page).to have_css('[data-date-picker-target="grid"] button[tabindex="0"]', visible: :all)
  end

  # Send a key to whichever grid button currently holds tabindex=0
  def grid_send(*keys)
    find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(*keys)
  end

  def focused_date
    page.evaluate_script('document.activeElement.dataset.datePickerDateParam')
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
        "document.activeElement === document.querySelector('[data-date-picker-target=\"button\"]')"
      )
      expect(display_focused).to be true
    end
  end

  describe 'Tab key focus trap' do
    it 'Tab from the focused day moves to the next month button' do
      open_picker
      grid_send(:tab)
      next_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"nextBtn\"]')"
      )

      # Prev button is disabled due to min value = today
      expect(page).to have_button('Previous month', disabled: true)
      expect(next_focused).to be true
    end

    it 'natural Tab from Previous month moves to Next month' do
      open_picker
      grid_send(:tab) # nextBtn
      find(':focus').click # enables prevButton
      grid_send(:tab) # prevBtn
      find('[data-date-picker-target="prevBtn"]').send_keys(:tab) # nextBtn
      next_focused = page.evaluate_script(
        "document.activeElement === document.querySelector('[data-date-picker-target=\"nextBtn\"]')"
      )
      expect(next_focused).to be true
    end

    it 'Shift+Tab from Previous month wraps back to the focused day' do
      open_picker
      grid_send(:tab) # nextBtn
      find(':focus').click # enables prevButton
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
  end

  describe 'legend' do
    it 'is hidden (but present) when there are no marked days' do
      open_picker
      legend = find('[data-date-picker-target="legend"]', visible: :all)
      expect(legend).to be_present
      expect(legend[:style]).to include('visibility: hidden')
    end

    context 'with marked days' do
      before { visit '/lookbook/preview/date_picker/with_marked_days' }

      it 'is visible when the current month has marked days' do
        open_picker
        legend = find('[data-date-picker-target="legend"]', visible: :all)
        expect(legend[:style]).to include('visibility: visible')
        expect(legend).to have_text('Existing appointment')
      end

      it 'hides when navigating to a month with no marked days' do
        open_picker
        # The preview marks today+2, +5, +9, +14 — the furthest is 2 weeks out.
        # Advancing 3 months puts us past all of them.
        3.times { find('[data-date-picker-target="nextBtn"]').click }
        legend = find('[data-date-picker-target="legend"]', visible: :all)
        expect(legend[:style]).to include('visibility: hidden')
      end
    end
  end

  describe 'skipping disabled dates' do
    before { visit '/lookbook/preview/date_picker/with_disabled_days' }

    it 'ArrowRight skips a disabled date and lands on the next enabled date' do
      open_picker
      # today+2 is disabled. Navigate to today+1 then confirm arrow skips to today+3.
      grid_send(:arrow_right)
      find('[data-date-picker-target="grid"] button[tabindex="0"]').send_keys(:arrow_right)
      # today+2 is disabled, so focus should land on today+3
      expect(focused_date).to eq((today + 3).iso8601)
    end
  end

  describe 'disabled weekends' do
    before do
      visit '/lookbook/preview/date_picker/with_weekends_disabled'
    end

    it 'weekends are disabled' do
      open_picker

      click_button 'Next month'

      weekend_days = Date.current.next_month.all_month.select do |d|
        d.saturday? || d.sunday?
      end

      weekend_days.each do |day|
        expect(page).to have_css("[data-date-picker-date-param='#{day.iso8601}'][disabled]")
      end
    end

    it 'ArrowRight skips a disabled date and lands on the next enabled date' do
      open_picker

      # arrow right enough to go over a weekend. So if it is Wed (3). 7-3 = 4, arrow right 4 times.
      # that would go over Thu, Fri, (Skip Sat, Sun), Mon, Tues.
      # We are using 7 instead of 6 because if the test runs on Sunday it won't arrow over.
      (7 - today.wday).times do
        grid_send(:arrow_right)
      end

      expect(focused_date).to eq((today + (9 - today.wday)).iso8601)
    end
  end
end
