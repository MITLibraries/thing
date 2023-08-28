class CreateDegreePeriods < ActiveRecord::Migration[7.0]
  def up
    create_table :degree_periods do |t|
      t.string :grad_month
      t.string :grad_year
      t.index [:grad_month, :grad_year], unique: true

      t.timestamps
    end

    # Seed the table with preexisting degree periods.
    grad_dates = Thesis.all.map(&:grad_date).uniq.sort.map do |date|
      { date.strftime('%B') => date.strftime('%Y') }
    end
    grad_dates.each do |date|
      DegreePeriod.create grad_month: date.keys.first,
                          grad_year: date.values.first
    end
  end

  def down
    drop_table :degree_periods
  end
end
