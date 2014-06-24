<% challenges.compact.each do |challenge| %>
<% implementor = challenge.implementor %>
<%= code_block challenge.source, implementor.language, :format => :rst %>
<% end %>
