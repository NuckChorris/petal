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

			string? avatar = obj.get_string_member("avatar");
			string? cover_image = obj.get_string_member("cover_image");
			var user = new User (obj.get_string_member("nane"));
			user.name = obj.get_string_member("name");
			user.location = obj.get_string_member("location");
			user.bio = obj.get_string_member("bio");
			user.avatar = new Soup.URI(avatar);
			user.cover_image = new Soup.URI(cover_image);
			return user;
		}
		public async List<Petal.Series>? search (string query) throws Error {
			return null;
		}
	}
	public class User : Object, Petal.User {
		User user = new User();
	}
}
