using System;
using System.IO;

namespace openstack.net
{
	public class RunChallenge
	{
		public static void Main (string[] args)
		{
			// Pacto cannot currently validate 100-Continue responses.  See https://github.com/thoughtworks/pacto/issues/87
			System.Net.ServicePointManager.Expect100Continue = false;
			var challenge = Path.GetFileNameWithoutExtension(args[0]);
			var challenge_class = Type.GetType("openstack.net." + challenge);
			var challenge_object = Activator.CreateInstance(challenge_class) as Challenge;
			challenge_object.Run(args);
		}
	}
}

