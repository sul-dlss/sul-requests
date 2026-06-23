# frozen_string_literal: true

module Home
  module CardView
    class FinesCardComponentPreview < ViewComponent::Preview
      layout 'lookbook'

      def empty
        render Home::FinesCardComponent.new(
          title: 'Fees and fines',
          icon: 'bi-cash-coin',
          fines: [],
          balance: 0,
          patron_key: 'preview',
          path: '#',
          past_path: '#'
        )
      end

      def with_balance
        render Home::FinesCardComponent.new(
          title: 'Fees and fines',
          icon: 'bi-cash-coin',
          fines: fake_fines,
          balance: 25.5,
          patron_key: 'preview',
          path: '#',
          past_path: '#'
        )
      end

      private

      def fake_fines
        [Struct.new(:key).new('fine-1'), Struct.new(:key).new('fine-2')]
      end
    end
  end
end
