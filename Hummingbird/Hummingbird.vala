// modules: glib-2.0 json-glib-1.0 libsoup-2.4 gmodule-2.0

namespace Hummingbird {
	internal struct HTTPReply {
		uint status;
		Json.Node? json;
	}
	internal errordomain HTTPError {
		SERVER_ERROR,
		BAD_GATEWAY,
		GATEWAY_TIMEOUT,
		WE_FUCKED_UP,
		THEY_FUCKED_UP,
		OTHER
	}
	public class Backend : Object, Petal.Backend, Petal.MultiUserBackend {
		internal static Soup.URI server = new Soup.URI("https://hbrd-v1.p.mashape.com/");
		internal string api_key { get; set; }
		internal Soup.Session session = new Soup.Session();
		public static Backend (string api_key) {
			this.api_key = api_key;
		}
		internal async HTTPReply api_call (string method, string path, string payload = "",
		                                   string content_type = "text/plain") throws Error {
			Soup.URI req = new Soup.URI.with_base(server, path);
			Soup.Message msg = new Soup.Message.from_uri(method, req);
			Soup.MessageHeaders headers = msg.request_headers;
			Soup.MessageBody body = msg.request_body;

			headers.append("X-Mashape-Authorization", api_key);
			headers.append("Accept", "application/json,*/*;q=0.8");
			headers.append("Content-Type", content_type);
			body.append_take(payload.data);

			Json.Parser parser = new Json.Parser();
			InputStream stream = yield session.send_async(msg);
			try {
				yield parser.load_from_stream_async(stream);
				return HTTPReply () {
					status = msg.status_code,
					json = parser.get_root()
				};
			} catch (Error e) {
				return HTTPReply () {
					status = msg.status_code,
					json = null
				};
			}
		}
		public async Petal.User? get_user (string username) throws Error {
			HTTPReply reply = yield api_call("GET", "/users/%s".printf(username));

			if (reply.status == Soup.Status.NOT_FOUND)
				return null;
			if (reply.status != Soup.Status.OK && reply.status % 500 < 100)
				throw new HTTPError.THEY_FUCKED_UP(reply.status.to_string());
			if (reply.status != Soup.Status.OK && reply.status % 400 < 100)
				throw new HTTPError.WE_FUCKED_UP(reply.status.to_string());

			Json.Object obj = reply.json.get_object();

			var user = new User(obj.get_string_member("name"));
			user.location = obj.get_string_member("location");
			user.bio = obj.get_string_member("bio");
			user.avatar = obj.get_string_member("avatar");
			user.cover_image = obj.get_string_member("cover_image");
			user.backend = this;
			return user;
		}
		public async List<Petal.Series>? search (string query) throws Error {
			return null;
		}
	}
	public class User : Object, Petal.User {
		internal Petal.Backend backend { get; set; }
		// TODO: get an API to set this stuff and update the profile
		public string avatar { get; internal set; }
		public string location { get; internal set; }
		public string bio { get; internal set; }
		public string cover_image { get; internal set; }
		public string username { get; internal set; }
		private string auth_token = null;
		public bool authenticated {
			get { return auth_token != null; }
		}
		internal User (string name) {
			this.username = name;
		}
		public async bool authenticate (string password) throws Error {
			Json.Node? root;
			Json.Builder builder = new Json.Builder();
			builder.begin_object();
			builder.set_member_name("username");
			// WORKAROUND for issue #10 on Hummingbird
			builder.add_string_value(username.down());
			builder.set_member_name("password");
			builder.add_string_value(password);
			builder.end_object();
			Json.Generator generator = new Json.Generator();
			generator.set_root(builder.get_root());

			HTTPReply reply = yield (backend as Backend).api_call("POST", "/users/authenticate",
			                                                      generator.to_data(null), "application/json");

			if (reply.status == Soup.Status.UNAUTHORIZED)
				return false;
			if (reply.status != Soup.Status.CREATED && reply.status % 500 < 100)
				throw new HTTPError.THEY_FUCKED_UP(reply.status.to_string());
			if (reply.status != Soup.Status.CREATED && reply.status % 400 < 100)
				throw new HTTPError.WE_FUCKED_UP(reply.status.to_string());

			auth_token = reply.json.get_string();
			return true;
		}
		public async Petal.Library? get_library () {
			return null;
		}
	}
}
