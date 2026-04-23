# frozen_string_literal: true

Sequel.migration do
  change do
    create_table?(:seats_held) do
      String :showing_id, null: false
      String :seat_id, null: false
      String :booking_id, null: false
      primary_key %i[showing_id seat_id]
      index :showing_id, name: 'idx_seats_held_showing'
    end
  end
end
