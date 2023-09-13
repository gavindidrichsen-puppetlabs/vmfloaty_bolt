#!/usr/bin/env ruby
require 'json'
require 'yaml'

class InventoryManager
  def initialize
    @inventory_json = fetch_inventory_json
    
  end

  def process_inventory
    parsed_json = parse_inventory_json
    save_inventory_yaml(parsed_json)
  end

  private

  def fetch_inventory_json
    # get json list of active vmfloaty VMs
    output = `floaty list --active --json`.strip

    # abort if empty string returned, i.e., no vmfloaty VMs
    raise 'Error fetching inventory json: Do you have any vmfloaty VMs?' if output.empty?

    output
  end

  def parse_inventory_json
    return [] if @inventory_json.empty?

    begin
      JSON.parse(@inventory_json)
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e.message}"
      {}
    end
  end

  def save_inventory_yaml(parsed_json)
    output = { 'targets' => [] }

    parsed_json.each do |key, value|
      target = {
        'name' => value['fqdn'],
        'uri' => value['fqdn'],
        'alias' => [],
        'config' => {
          'transport' => 'ssh',
          'ssh' => {
            'batch-mode' => true,
            'cleanup' => true,
            'connect-timeout' => 10,
            'disconnect-timeout' => 5,
            'load-config' => true,
            'login-shell' => 'bash',
            'tty' => false,
            'host-key-check' => false,
            'private-key' => '~/.ssh/id_rsa-acceptance',
            'run-as' => 'root',
            'user' => 'root'
          }
        }
      }
      output['targets'] << target
    end

    output_file_path = './inventory.yaml'
    begin
      File.open(output_file_path, 'w') { |file| file.write(output.to_yaml) }
      puts "Inventory.yaml generated successfully at #{output_file_path}"
    rescue StandardError => e
      puts "Error writing YAML file: #{e.message}"
      exit(1)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  inventory_manager = InventoryManager.new
  inventory_manager.process_inventory
end
