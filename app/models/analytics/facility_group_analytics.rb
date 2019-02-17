class Analytics::FacilityGroupAnalytics
  attr_reader :facility_group, :days_previous, :months_previous, :from_time, :to_time

  def initialize(facility_group, from_time: Time.new(0), to_time: Time.now, days_previous: 7, months_previous: 12)
    @facility_group = facility_group
    @days_previous = days_previous
    @months_previous = months_previous
    @from_time = from_time
    @to_time = to_time
  end

  def newly_enrolled_patients
    Patient.where(registration_facility: facility_group.facilities)
      .where(device_created_at: from_time..to_time)
      .distinct
  end

  def returning_patients
    Patient.where(registration_facility: facility_group.facilities)
      .where('device_created_at <= ?', from_time)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? && latest_blood_pressure.device_created_at >= from_time && latest_blood_pressure.device_created_at < to_time)
    end
  end

  def non_returning_hypertensive_patients
    non_returning_hypertensive_patients_in_period(from_time)
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    return @non_returning_hypertensive_patients_per_month if @non_returning_hypertensive_patients_per_month.present?
    @non_returning_hypertensive_patients_per_month = {}
    number_of_months.times do |n|
      before_time = (to_time - n.months).at_beginning_of_month
      @non_returning_hypertensive_patients_per_month[before_time] = non_returning_hypertensive_patients_in_period(before_time).size || 0
    end
    @non_returning_hypertensive_patients_per_month.sort
  end

  def hypertensive_patients_recorded_in_period(from_time, to_time)
    BloodPressure.hypertensive
      .where(facility: facility_group.facilities)
      .where("device_created_at >= ?", from_time)
      .where("device_created_at <= ?", to_time)
      .pluck(:patient_id)
      .uniq
  end

  def patients_under_control_in_period(patient_ids, from_time, to_time)
    Patient.where(id: patient_ids)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? &&
        latest_blood_pressure.under_control? &&
        latest_blood_pressure.device_created_at >= from_time &&
        latest_blood_pressure.device_created_at < to_time)
    end
  end

  def control_rate_for_period(from_time, to_time)
    hypertensive_patients_ids = hypertensive_patients_recorded_in_period(from_time - 9.months, to_time - 9.months)

    numerator = patients_under_control_in_period(hypertensive_patients_ids, from_time, to_time).size
    denominator = hypertensive_patients_ids.count

    (numerator * 100.0 / denominator).round unless denominator == 0
  end

  def control_rate
    control_rate_for_period(from_time, to_time)
  end

  private

  def non_returning_hypertensive_patients_in_period(before_time)
    Patient.where(registration_facility: facility_group.facilities)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      latest_blood_pressure.present? && latest_blood_pressure.hypertensive? && patient.latest_blood_pressure.device_created_at < before_time
    end
  end

  def blood_pressures_in_facility_group(facility_group)
    BloodPressure.where(facility: facility_group.facilities)
  end
end