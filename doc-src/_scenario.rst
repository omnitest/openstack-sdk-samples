<% challenges.compact.each do |challenge| %>
<% implementor = Polytrix.implementors.find{|i| i.name == challenge.implementor } %>
.. code-block:: <%= implementor.language %>
<%= File.read(challenge.source_file) %>

<% end %>
