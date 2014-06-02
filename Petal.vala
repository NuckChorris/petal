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
	CURRENTLY_WATCHING,
	PLAN_TO_WATCH,
	COMPLETED,
	ON_HOLD,
	DROPPED
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
public interface Petal.Series : Object {
	public abstract string title { get; }
	public abstract string total_episodes { get; }
}
public interface Petal.Status : Object {
	private abstract Petal.Backend backend { get; }
	public abstract Petal.User user { get; }
	public abstract Petal.WatchingStatus status { get; }
	public abstract Petal.Series series { get; }
	public abstract uint watched { get; }

	public abstract async bool increment () throws Error;
	public abstract async int? set_watched (uint watched) throws Error;
	public abstract async int? set_status (Petal.WatchingStatus status) throws Error;
}
public interface Petal.Library : Object {
	private abstract Petal.Backend backend { get; }
	private abstract Petal.User user { get; }

	public abstract List<Petal.Status> get_list () throws Error;

	public virtual async bool synchronize (Petal.Library other_library) throws Error {
		return false;
	}
}
public interface Petal.User : Object {
	internal abstract Petal.Backend backend { get; set; }
	public abstract string username { get; internal set; }
	public abstract bool authenticated { get; internal set; default = false; }
	public abstract async bool authenticate (string password) throws Error;
	public abstract async Petal.Library? get_library () throws Error;
}
