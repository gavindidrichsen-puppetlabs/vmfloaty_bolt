#!/usr/bin/env ruby

require 'json'
require 'yaml'

# Load JSON data from file
json_file_path = './inventory.d/vmfloaty/inventory.json'

begin
  json_data = File.read(json_file_path)
rescue StandardError => e
  puts "Error reading JSON file: #{e.message}"
  exit(1)
end

# Parse the JSON data into a Ruby hash
data = JSON.parse(json_data)

# Create the YAML output
output = { 'targets' => [] }

# Iterate over the data and create a target for each entry
data.each do |_name, info|
  target = {
    'name' => info['fqdn'],
    'uri' => info['fqdn'],
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

# Save the YAML as "inventory.yaml"
output_file_path = './inventory.yaml'
begin
  File.open(output_file_path, 'w') { |file| file.write(output.to_yaml) }
  puts "Inventory.yaml generated successfully at #{output_file_path}"
rescue StandardError => e
  puts "Error writing YAML file: #{e.message}"
  exit(1)
end
