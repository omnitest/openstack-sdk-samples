RSpec::Matchers.define :have_validated_service do |group_name, service_name|
  @requested_name = service_name
  @contract = Pacto.contract_registry.find{ |c| c.name == @requested_name }
  match do
    unless @contract.nil?
      @validations = Pacto::ValidationRegistry.instance.validations.select {|v|
        # FIXME: Same contract on multiple servers is currently problematic
        v.contract && v.contract.name == @contract.name
      }
      !(@validations.empty? || @validations.map(&:successful?).include?(false))
    end
  end

  failure_message_for_should do
    buffer = StringIO.new
    buffer.puts "expected Pacto to have validated #{@requested_name}"
    if @contract.nil?
      buffer.puts '  but no known contract matches that name'
    elsif @validations.empty?
      buffer.puts '  but no request matched the pattern'
      buffer.puts "    pattern: #{@contract.request_pattern}"
      buffer.puts '    received:'
      buffer.puts "#{WebMock::RequestRegistry.instance}"
    elsif @validations.map(&:successful?).include?(false)
      buffer.puts '  but validation errors were found:'
      buffer.print '    '
      validation_results = @validations.map(&:results).flatten.compact
      buffer.puts validation_results.join "\n    "
      validation_results.each do |validation_result|
        buffer.puts "    #{validation_result}"
      end
    else
      # FIXME: ensure this is unreachable?
      buffer.puts '  but an unknown problem occurred'
    end
    buffer.string
  end
end
