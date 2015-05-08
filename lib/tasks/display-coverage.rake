desc 'Display coveralls current coverage metric'
task :display_coveralls_coverage do
  coverage_file_path = File.join(Rails.root, 'coverage', '.last_run.json')
  coverage_result_path = File.join(Rails.root, 'coverage', '.resultset.json')
  if File.exist?(coverage_file_path) && File.exist?(coverage_result_path)
    coverage_file = File.read(coverage_file_path)
    coverage_result_file = File.read(coverage_result_path)
    coverage = JSON.parse(coverage_file)
    results = JSON.parse(coverage_result_file)
    if coverage['result'] && coverage['result']['covered_percent']
      puts "#{coverage['result']['covered_percent']}% code coverage"
    end
    if results['RSpec'] && results['RSpec']['coverage']
      untested_files = results['RSpec']['coverage'].select do |_, values|
        values.any? { |v| v == 0 }
      end
      if untested_files.present?
        puts "#{untested_files.keys.length} untested files:"
        untested_files.each do |key, lines|
          untested_lines = list_of_untested_lines(lines)
          puts "\t#{key}: #{lines.count { |v| v == 0 }} untested lines: #{untested_lines.inspect}"
        end
        fail 'Untested files!'
      end
    end
  else
    puts 'Unable to read coverage metrics'
  end
end

def list_of_untested_lines(lines)
  lines.each_with_index.map do |line, index|
    (index + 1) if line == 0
  end.compact
end
