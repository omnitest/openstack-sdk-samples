RSpec::Matchers.define :have_validated_service do |group_name, service_name|
  @requested_name = service_name
  @contract = Pacto.contract_registry.find{ |c| c.name == @requested_name }
  match do
    unless @contract.nil?
      @investigations = Pacto::InvestigationRegistry.instance.investigations.select {|v|
        # FIXME: Same contract on multiple servers is currently problematic
        v.contract && v.contract.name == @contract.name
      }
      !(@investigations.empty? || @investigations.map(&:successful?).include?(false))
    end
  end

  failure_message_for_should do
    buffer = StringIO.new
    buffer.puts "expected Pacto to have validated #{@requested_name}"
    if @contract.nil?
      buffer.puts '  but no known contract matches that name'
    elsif @investigations.empty?
      buffer.puts '  but no request matched the pattern'
      buffer.puts "    pattern: #{@contract.request_pattern}"
      buffer.puts '    received:'
      buffer.puts "#{WebMock::RequestRegistry.instance}"
    elsif @investigations.map(&:successful?).include?(false)
      buffer.puts '  but investigation errors were found:'
      buffer.print '    '
      investigation_results = @investigations.map(&:results).flatten.compact
      buffer.puts investigation_results.join "\n    "
      investigation_results.each do |investigation_result|
        buffer.puts "    #{investigation_result}"
      end
    else
      # FIXME: ensure this is unreachable?
      buffer.puts '  but an unknown problem occurred'
    end
    buffer.string
  end
end
