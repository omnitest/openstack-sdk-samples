<% challenges.compact.each do |challenge| %>
<% implementor = challenge.implementor %>
.. code-block:: <%= implementor.language %>
<%= File.read(challenge.source_file) %>

<% end %>
