w = Window.new("GUI Introduction", Rect(200,200,500,500));
z= 3.collect({|i| Slider.new(w, Rect(i*30, 0, 30, 500))});
w.front
z.value_(0.47)
~slider=[0,0,0];
z[2].value_(~slider[2])
(
r=Routine.new({
	{
		~slider=~slider*0.99;
		3.do({|i| b[i].set(~slider[i])});
		0.1.yield;
	}.loop;
}).play;
)
r.stop
a = LevelIndicator(bounds:Rect(100, 100, 100, 400)).front;
    a.onClose_({ x.free; o.free; });

{
	a.value = 1.0.rand;
	0.1.yield;
}.fork
o = OSCFunc({arg msg;
    {
        a.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
        a.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
    }.defer;
}, '/levels', s.addr);

Quarks.gui

b = Array.fill(3, {Bus.control(s, 1)});
b.free
ControlBusMeter.new(s, [0,3])
b.get({|val| val.postln});
b.index

{Out.kr(0, 1)}.play
b.getSynchronous
r.stop
SendReply
3.do({|i|
	b[i].set(~slider[i])
});
b[0].set(~slider[0])
b[1].set(~slider[1])
~slider[1]=0.6
b[0].free
b