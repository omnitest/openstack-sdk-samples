using System;
using net.openstack.Providers.Rackspace;
using net.openstack.Core.Providers;
using net.openstack.Core.Exceptions.Response;
using net.openstack.Providers.Rackspace.Objects;


namespace openstack.net
{
	class AuthenticateToken : Challenge
	{
		public int Run (string[] args)
		{
			var auth_url = new Uri(Environment.GetEnvironmentVariable ("OS_AUTH_URL"));
			Console.WriteLine ("Connecting to " + auth_url);
			IIdentityProvider identityProvider = new CloudIdentityProvider (null, null, null, auth_url);

			// In this example we're getting our credentials from environment variables
			// asdf

			identityProvider.Authenticate (new RackspaceCloudIdentity {
				Username = Environment.GetEnvironmentVariable("RAX_USERNAME"),
				APIKey = Environment.GetEnvironmentVariable("RAX_API_KEY")
			});
			Console.WriteLine ("Authenticated!");
			return 0;
		}
	}
}
