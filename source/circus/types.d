module circus.types;

public class Boxed(T)
{
	T _v;
	alias _v this;
	this(in T v) immutable {_v = v;}
}
