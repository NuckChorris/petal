// modules: glib-2.0 gmodule-2.0 gio-2.0
/* Petal Interfaces
 *
 * Petal is a multi-backend anime library management solution implemented in Vala.  These
 * interfaces are thoroughly abstracted to hide complexity and increase generality.
 *
 * For example, the LevelDB backend spins up a thread on instantiation, and all the "async" methods
 * actually queue a message to the LevelDB thread.  The Hummingbird backend, on the other hand, is
 * asynchronous because it uses libsoup.
 *
 * Petal also allows each interface to handle its own system for User authentication internally, or
 * eschew authentication entirely (as LevelDB does), if they disable the multi_user flag.
 */
public enum Petal.WatchingStatus {
	DROPPED = 0,
	ON_HOLD = 1,
	PLAN_TO_WATCH = 2,
	CURRENTLY_WATCHING = 3,
	COMPLETED = 4
}
public enum Petal.AiringStatus {
	NOT_YET_AIRED = 0,
	CURRENTLY_AIRING = 1,
	FINISHED_AIRING = 2
}
public enum Petal.ShowType {
	TV = 0,
	OVA = 1,
	SPECIAL = 2,
	MOVIE = 3
}
public interface Petal.Backend : Object {
	public abstract async List<Petal.Series>? search (string query) throws Error;
}
public interface Petal.MultiUserBackend : Object, Petal.Backend {
	public abstract async Petal.User? get_user (string user) throws Error;
}
public interface Petal.SingleUserBackend : Object, Petal.Backend {
	public abstract async Petal.Library? get_library () throws Error;
}
public interface Petal.User : Object, AsyncInitable {
	public abstract string username { get; internal set; }
	public abstract bool authenticated { get; }
	public abstract async bool authenticate (string password) throws Error;
	public abstract async Petal.Library? get_library () throws Error;
}
public interface Petal.Library : Object, AsyncInitable {
	public abstract unowned List<Petal.Status> get_list_by_status (Petal.WatchingStatus status) throws Error;
	public abstract unowned List<Petal.Status> get_list () throws Error;
	public abstract void add_item (Petal.Status status) throws Error;

	public virtual async bool synchronize (Petal.Library other_library) throws Error {
		return false;
	}
}
public interface Petal.Series : Object, AsyncInitable {
	public abstract Petal.AiringStatus? status { get; internal set; }
	public abstract Petal.ShowType? show_type { get; internal set; }
	public abstract string url { get; internal set; }
	public abstract string cover_image { get; internal set; }
	public abstract string synopsis { get; internal set; }
	public abstract string title { get; internal set; }
	public abstract uint total_episodes { get; internal set; }
}
public interface Petal.Status : Object, Petal.Series, AsyncInitable {
	public abstract Petal.WatchingStatus status { get; }
	public abstract uint watched { get; }

	public abstract async bool increment () throws Error;
	public abstract async int? set_watched (uint watched) throws Error;
	public abstract async int? set_status (Petal.WatchingStatus status) throws Error;
}
