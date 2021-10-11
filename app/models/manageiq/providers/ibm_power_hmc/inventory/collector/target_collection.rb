class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::TargetCollection < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
  end

  def cecs
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    @cecs ||= manager.with_provider_connection do |connection|
      references(:hosts).map do |ems_ref|
        connection.managed_system(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying managed system #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact
    end
  end

  def lpars
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    @lpars ||= manager.with_provider_connection do |connection|
      references(:vms).map do |ems_ref|
        connection.lpar(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying lpar #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact
    end
  end

  def vioses
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    @vioses ||= manager.with_provider_connection do |connection|
      references(:vms).map do |ems_ref|
        connection.vios(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying vios #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact
    end
  end

  private

  def parse_targets!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    target.targets.each do |target|
      case target
      when Host
        add_target(:hosts, target.ems_ref)
      when ManageIQ::Providers::IbmPowerHmc::InfraManager::Lpar, ManageIQ::Providers::IbmPowerHmc::InfraManager::Vios
        add_target(:vms, target.ems_ref)
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end
