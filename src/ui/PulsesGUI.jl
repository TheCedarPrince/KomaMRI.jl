loadbutton = filepicker()
columnbuttons = Observable{Any}(dom"div"())
data = Observable{Any}(Array{Sequence})
map!(f->begin
        print("Loading... $f\n")
        JLD2.load(FileIO.File{FileIO.DataFormat{:JLD2}}(f),"seq")
    end
    , data, loadbutton)

p = PlotlyJS.plot()
hh, ww = 800, 800
kspace = MRIsim.get_designed_kspace(seq[1])
l = PlotlyJS.Layout(;title="k-space", yaxis_title="ky [m^-1]",
    xaxis_title="kx [m^-1]",#height=hh,width=ww,
    modebar=attr(orientation="v"),legend=false)
line = PlotlyJS.scatter(x=kspace[:,1],y=kspace[:,2],mode="lines")
marker = PlotlyJS.scatter(x=kspace[:,1],y=kspace[:,2],mode="markers",
    marker=attr(size=5,color=1:length(kspace),colorscale="Jet"))
p = PlotlyJS.plot([line,marker],l)
plt = Observable{Any}(p)

function makebuttons(df)
    namesdf = 1:length(df)
    buttons = button.(string.())
    for (btn, name) in zip(buttons, namesdf)
        map!(t -> begin
            p = PlotlyJS.plot(df[name][:])
            PlotlyJS.relayout!(p,height=hh)
            p
            end
            , plt, btn)
    end
    dom"div"(hbox(buttons))
end

map!(makebuttons, columnbuttons, data)
pulseseq = dom"div"(loadbutton, columnbuttons, plt)
content!(w, "div#content", pulseseq)