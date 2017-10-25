+ Env {
	asBuf {|buf|
		var array = Array.fill(buf.numFrames, {|i| this[i/buf.numFrames]});
		buf.setn(0, array);
		^this;
	}
}
