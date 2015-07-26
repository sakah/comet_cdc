###############
# Global vars #
###############
diam = 180
w = 650
h = 650

margin = {top: 20, right: 150, bottom: 50, left: 80}
width = w - margin.left - margin.right
height = 300 - margin.top - margin.bottom

numWires = [ 
   396, 396, 396, 408, 408, 420, 420,
   432, 432, 444, 444, 456, 456, 468, 
   468, 480, 480, 492, 492, 504, 504, 
   516, 516, 528, 528, 540, 540, 552, 
   552, 564, 564, 576, 576, 588, 588, 
   600, 600, 612, 612
]

numTotalWires = _.reduce(numWires, (memo, num) -> memo+num)

get_xypos = (layerid, wireid, num_wires) ->
   r = 50+(layerid-1)
   deg = (wireid-1)/num_wires*360
   rad = deg/180.0*Math.PI
   x = r*Math.cos(rad)
   y = r*Math.sin(rad)
   {x: x, y: y}

holes = []
for num,i in numWires
  for j in [0..num]
    holes.push(get_xypos(i+1, j+1, numWires[i]))

#############
# Functions #
#############
append_svg = (id) ->
  d3.select(id).append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

make_frame = (svg, xtitle, ytitle, xdomain, ydomain, options) ->
  svg.selectAll("g").remove()

  xScale=""
  if options.xaxis_type=="roundBands"
    #console.log("select xaxis roundBands")
    xScale = d3.scale.ordinal().domain(xdomain).rangeRoundBands([0, width])
  else if options.xaxis_type=="time"
    #console.log("select xaxis time")
    xScale = d3.time.scale().domain(xdomain).range([0, width]).nice()
  else
    #console.log("select xaxis linear")
    xScale = d3.scale.linear().domain(xdomain).range([0, width])
 
  yScale = d3.scale.linear().domain(ydomain).range([height, 0]).nice()

  if not options.no_axis
    tick_label_dx = 0
    tick_label_dy = 10
    tick_label_rotate = "0"
    xAxis = d3.svg.axis().scale(xScale).orient("bottom")

    if options.xaxis_tickValues?
      #console.log(options.xaxis_tickValues);
      xAxis.tickValues(options.xaxis_tickValues)

    if options.xaxis_type=="time"
      xAxis.ticks(5).tickFormat(d3.time.format('%b %d'))
      tick_label_rotate = "-65"
      tick_label_dx = -30
      tick_label_dy = -1

    yAxis = d3.svg.axis().scale(yScale).orient("left")

    xx = svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis)

    xx.selectAll("text")
      .attr("transform", "rotate("+tick_label_rotate+")")
      .attr("text-anchor", "start")
      .attr("dx", tick_label_dx)
      .attr("dy", tick_label_dy)

    xx.append("text")
            .attr("x", width+8)
            .attr("y", 10)
            .attr("text-anchor", "start")
            .text(xtitle)

  svg.append("g")
     .attr("class", "axis")
     .call(yAxis)
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", -55)
     .attr("dy", ".71em")
     .style("text-anchor", "end")
     .text(ytitle)

  { "svg": svg, "xScale": xScale, "yScale": yScale }


makeBarChart = (frame, data, xdata, ydata, fillColor, tooltip) ->
  frame.svg.selectAll("rect").remove()
  frame.svg.selectAll(".bar")
       .data(data)
       .enter().append("rect")
       .attr("fill",fillColor)
       .attr("x", (d) -> frame.xScale(d[xdata]))
       .attr("width", frame.xScale.rangeBand()*0.97)
       #.attr("width", frame.xScale.rangeBand() - 5)
       .attr("y", height)
       .attr("height", 0)
       .transition()
       .duration(1000)
       .attr("y", (d, i) -> frame.yScale(d[ydata]))
       .attr("height", (d) -> height - frame.yScale(d[ydata]))

  makeTooltip(frame, "rect", data, xdata, ydata, tooltip.label) if (tooltip)


makeScatterPlot = (frame, data, xdata, ydata, options, legend_entry, tooltip) ->
  if options.line_stroke
    line = d3.svg.line()
          .x((d)-> frame.xScale(d[xdata]))
          .y((d)-> frame.yScale(d[ydata]))
    frame.svg.append("path")
         .attr("stroke", options.line_stroke)
         .attr("fill", "none")
         .attr("d", line(data))

  frame.svg.selectAll("circle").remove()

  if legend_entry.length!=0
    #add legend   
    legend = frame.svg.append("g")
              .attr("x", width - 65)
              .attr("y", 25)
              .attr("height", 100)
              .attr("width", 100)
              .selectAll("text")
              .data(legend_entry)
              .enter()
              .append("text")
              .attr("x", w-180)
              .attr("y", (d)-> d.ypos)
              .attr("height",30)
              .attr("width",100)
              .style("fill", (d) -> d.stroke)
              .text((d) -> d.label)

    frame.svg.append("g")
         .attr("x", width - 75)
         .attr("y", 25)
         .attr("height", 100)
         .attr("width", 100)
         .selectAll(".circle")
         .data(legend_entry)
         .enter()
         .append("circle")
         .attr("cx", w-190)
         .attr("cy", (d)-> d.ypos - 4)
         .attr("r", 3)
         .attr("fill", (d)-> d.fill)
         .attr("stroke",(d)-> d.stroke)
         .attr("stroke-width", "1px")

  frame.svg.selectAll(".circle")
       .data(data)
       .enter()
       .append("g")
       .attr("class","dot") # Need to distinguish from circle for legend
       .append("circle")
       .attr("cx", (d,i)-> frame.xScale(d[xdata]))
       .attr("cy", (d,i)-> frame.yScale(d[ydata]))
       .attr("r",  3)
       .attr("fill", options.fill)
       .attr("stroke",options.stroke)
       .attr("stroke-width", options.stroke_width)

  makeTooltip(frame, ".dot circle", data, xdata, ydata, tooltip.label) if (tooltip) 


makeLine = (frame, class_name, points) -> 
  line = d3.svg.line().x((d) -> frame.xScale(d.x)).y((d) ->frame.yScale(d.y))
  frame.svg.append("path").datum(points).attr("class", class_name).attr("d", line)


makeStatBox = (frame, x, y, text) -> 
  frame.svg.select("text").remove()
  frame.svg.append("text")
       .attr("x", x)
       .attr("y", y)
       .text(text)

makeTooltip = (frame, class_name, data, xdata, ydata, labels) -> 
  focus = frame.svg.append("g").attr("class","focus").style("display","none")
  focus.append("rect").attr("opacity","0.6").attr("x",9).attr("y",9).attr("rx",2).attr("ry",2).attr("width",30)
        .attr("height", -> if labels.length==1 then return 20 else return labels.length*17)

  focus.selectAll("text").data(labels).enter().append("text")
       .attr("x", 14)
       .attr("y", 12)
       .attr("font-family", "Inconsolata")
       .attr("font-size", "10px")
       .attr("fill", "white");

  get_msg = (d, label, i) -> 
    msg = label.prefix || ''
    for ent,i in label.data
      if typeof(ent)=='function' then msg += ent(d) else msg += d[ent]
      msg += label.separator || '' if (i<label.data.length-1) 
    msg += label.postfix || ''

  frame.svg.selectAll(class_name)
       .data(data)
       .on "mouseover", -> focus.style("display", null)
       .on "mouseout" , -> focus.style("display", "none") 
       .on "mousemove", (d) -> 
           xval = if (typeof(xdata)=='function') then xdata(d) else d[xdata]
           yval = if (typeof(ydata)=='function') then ydata(d) else d[ydata]
           focus.select("rect").attr("transform", "translate(" + frame.xScale(xval) + "," + (frame.yScale(yval)-10) + ")")
           focus.select("rect").attr("width", ->
             line = []
             focus.selectAll("text").each (label, i) -> line.push(get_msg(d, label, i))
             max_len = d3.max(line, (d) -> d.length)
             #console.log(line)
             14+max_len*4.7)

           focus.selectAll("text").attr("transform", (_,i) -> "translate(#{frame.xScale(xval)}, #{frame.yScale(yval)+i*15})")
           focus.selectAll("text").text (label,i) -> get_msg(d, label, i)

class S3
  constructor: ->
    @awsRegion = "us-east-1"
    @cognitoParams = IdentityPoolId: "us-east-1:435dfdc9-d483-4f5e-8f8b-27e3569ad9af"
    @s3BucketName = "comet-cdc"
    @s3RegionName = "ap-northeast-1"
    AWS.config.region = @awsRegion
    AWS.config.credentials = new AWS.CognitoIdentityCredentials(@cognitoParams)
    AWS.config.credentials.get (err) -> console.log "Cognito Identity Id: " + AWS.config.credentials.identityId if (!err) 
    @s3 = new AWS.S3 {params: {Bucket: @s3BucketName, Region: @s3RegionName}}
    console.log("=== s3 ====");
    console.log(@s3);
    console.log("===========");


   getObject: (name, callback) ->
     @s3.listObjects (err, data) =>
       for obj in data.Contents when obj.Key==name
         callback @s3.getSignedUrl('getObject', {Bucket: @s3BucketName, Key: obj.Key})

class DialGauge
  read_csv: (csv) ->
    j=0
    data=[]
    for ent in csv
      v11 = ent["10deg_1mm"]
      v12 = ent["10deg_10um"]
      v21 = ent["90deg_1mm"]
      v22 = ent["90deg_10um"]
      v31 = ent["180deg_1mm"]
      v32 = ent["180deg_10um"]
      v41 = ent["270deg_1mm"]
      v42 = ent["270deg_10um"]
      continue if ( !v11 || !v21 || !v31 || !v41)
      continue if ( !v12 || !v22 || !v32 || !v42)

      v1 = (parseFloat(v11)+parseFloat(v12))*1000 #mm -> um
      v2 = (parseFloat(v21)+parseFloat(v22))*1000 #mm -> um
      v3 = (parseFloat(v31)+parseFloat(v32))*1000 #mm -> um
      v4 = (parseFloat(v41)+parseFloat(v42))*1000 #mm -> um
      if j==0
        v1_start = v1
        v2_start = v2
        v3_start = v3
        v4_start = v4

      d1 = v1 - v1_start
      d2 = v2 - v2_start
      d3 = v3 - v3_start
      d4 = v4 - v4_start

      utime = Date.parse "#{ent["Date"]} #{ent["Time"]}"
      date = ent["Date"]
      time = ent["Time"]
      temp = ent["Temp"]

      data[j++] = { "utime": utime, "date":  date, "time":  time, "temp":  temp, "location": "at10deg",  "disp_um": parseFloat(d1) }
      data[j++] = { "utime": utime, "date":  date, "time":  time, "temp":  temp, "location": "at90deg",  "disp_um": parseFloat(d2) }
      data[j++] = { "utime": utime, "date":  date, "time":  time, "temp":  temp, "location": "at180deg", "disp_um": parseFloat(d3) }
      data[j++] = { "utime": utime, "date":  date, "time":  time, "temp":  temp, "location": "at270deg", "disp_um": parseFloat(d4) }

    #console.log data
    data

  plot: (csv) ->
    gauge_data = @read_csv(csv)
    xdomain_gauge = d3.extent(gauge_data, (d) -> d.utime)
    ydomain_gauge = d3.extent(gauge_data, (d) -> d.disp_um)
    svg_gauge = append_svg("#menu_gauge")
    frame_gauge = make_frame(svg_gauge, "date", "displacement (um)", xdomain_gauge, ydomain_gauge, {xaxis_type: "time"})
    stroke_gauge = {at10deg:"#ed5454", at90deg:"#3874e3", at180deg:"#228b22", at270deg:"#ffa500" }
    fill_gauge   = {at10deg:"#f8d7d7", at90deg:"#bdd0f4", at180deg:"#9acd32", at270deg:"#ffead6" }
    makeScatterPlot frame_gauge, gauge_data, "utime", "disp_um",
                         { 
                           fill: (d) -> fill_gauge[d.location]
                           stroke: (d) -> stroke_gauge[d.location]
                           stroke_width: "1px"
                         }
                         [
                           label:"10deg",  stroke:'#ed5454', fill: "#f8d7d7", ypos:"66" 
                           label:"90deg",  stroke:'#3874e3', fill: "#bdd0f4", ypos:"83" 
                           label:"180deg", stroke:'#228b22', fill: "#9acd32", ypos:"100"
                           label:"270deg", stroke:'#ffa500', fill: "#ffead6", ypos:"117"
                         ]
                         {
                           label: [ {data: [ "date", "time", (d) -> d.disp_um.toFixed(0)], separator:' ', postfix:' um'}]
                         }

class TensionBar
  @read_csv: (csv) ->
    data=[]
    for ent in csv
      d1 = ent["Date"]
      d2 = ent["Tension_kg"]
      #console.log("d1 " + d1)
      #console.log("d2 " + d2)
      continue if ( _.isEmpty(d1) || _.isEmpty(d2))
  
      utime = Date.parse(d1)
      #console.log("csv " + csv[i] + " Date " + d1 +  " utime " + utime);
      tension_kg = parseFloat(d2)
 
      data.push { utime: utime, tension_kg: tension_kg }
  
    #console.log(data);
    data

  @plot: (csv, dailies) =>
    bar_data = @read_csv(csv)
    #for bar,j in bar_data
    #  console.log("j " + j)
    #  console.log("bar_data.utime " + bar.utime)
    #  console.log("bar_data.tension_kg " + bar.tension_kg)
    
    for daily,i in dailies
      jlast = 0
      for bar,j in bar_data
        #console.log("i " + i)
        #console.log("j " + j)
        #console.log(" dailies.utime " + dailies[i].utime)
        #console.log("bar_data.utime " + bar_data[j].utime)
        #console.log("bar_data.tension_kg " + bar_data[j].tension_kg)
        jlast = j -1
        break if (bar.utime > daily.utime) 
        #console.log("breaked at i " + i + " j " + j);
   
      daily.bar_tension_kg = bar_data[jlast].tension_kg
      daily.all_tension_kg = daily.wire_tension_kg + bar_data[jlast].tension_kg
  
    # TensionBar + Wire
    ydomain_all = [0.9*d3.min(dailies, (d) -> d.all_tension_kg), 1.1*d3.max(dailies, (d) -> d.all_tension_kg)]
    svg_all = append_svg("#menu_load_all")
    frame_all = make_frame(svg_all, "date", "total loading (kg)", xdomain, ydomain_all, {xaxis_type: "time"})
    makeScatterPlot(frame_all, dailies, "utime", "all_tension_kg", 
                                        {fill: "#9966ff", stroke: "#6633cc", stroke_width: "1px", line_stroke: "#6633cc" }, [],
                                        { label: [ { data: [ labelA, ((d) -> "#{d.all_tension_kg.toFixed(1)} kg")], separator:' '} ]})
     
    # TensionBar
    ydomain_bar = [0.9*d3.min(dailies, ((d) -> d.bar_tension_kg)), 1.1*d3.max(dailies, ((d) -> d.bar_tension_kg))]
    #console.log("xdomain_bar " + xdomain_bar);
    #console.log("ydomain_bar " + ydomain_bar);
    svg_bar = append_svg("#menu_load_bar")
    frame_bar = make_frame(svg_bar, "date", "loading of tension bars (kg)", xdomain, ydomain_bar, {xaxis_type: "time"})
    makeScatterPlot(frame_bar, dailies, "utime", "bar_tension_kg", { fill: "#0081B8", stroke: "blue", stroke_width: "1px", line_stroke: "blue"}, [],
                                         { label: [ { data: [ labelA, ((d) -> "#{d.bar_tension_kg.toFixed(1)} kg")], separator:' '} ]})


#xml_name = "test.xml";
#xml_name = "./xml/COMETCDC.xml";
#json_name = "./stats/stats.json";
#{"date":"2015/05/26","utime":1432566000000,"days":1,"num_sum":11,"num_sense":0,"num_field":11,"num_day":11,"num_ave":11.0,"num_bad":10,"wire_tension_kg":0.9997800000000001,"last_date":"2022/03/31","last_utime":1648652400000}


class Progress
  @plot: (dailies) ->
    #xdomain =  _.map(dailies, (d) ->d.days)
    xdomain = (d.days for d in dailies)
    ydomain_sum = [0, d3.max(dailies, (d) -> d.num_sum)]
    ydomain_day = [0, d3.max(dailies, (d) -> d.num_day)]
    ydomain_ave = [0, d3.max(dailies, (d) -> d.num_ave)]
    ydomain_bad = [0, d3.max(dailies, (d) -> d.num_bad)]
  
    svg_progress_sum = append_svg("#menu_progress #progress_sum")
    svg_progress_day = append_svg("#menu_progress #progress_day")
    svg_progress_ave = append_svg("#menu_progress #progress_ave")
    svg_progress_bad = append_svg("#menu_progress #bad_wires")
  
    frame_progress_sum = make_frame(svg_progress_sum, "days", "total # of stringed wires",     xdomain, ydomain_sum, {xaxis_type: "roundBands"})
    frame_progress_day = make_frame(svg_progress_day, "days", "# of stringed wires",           xdomain, ydomain_day, {xaxis_type: "roundBands"})
    frame_progress_ave = make_frame(svg_progress_ave, "days", "ave # of stringed wires",       xdomain, ydomain_ave, {xaxis_type: "roundBands"})
    frame_progress_bad = make_frame(svg_progress_bad, "days", "# of wires to be re-stringed",  xdomain, ydomain_bad, {xaxis_type: "roundBands"})
  
    $("#last_day").html("Finished on "+new Date(_.last(dailies).last_utime).toLocaleDateString("ja-JP"))
    makeBarChart(frame_progress_sum, dailies, "days","num_sum", "#D70071", {label: [ {data: ["num_sum"]} ]})
    makeBarChart(frame_progress_ave, dailies, "days","num_ave", "#91D48C", {label: [ {data: [(d)->d.num_ave.toFixed(1)]} ]})
    makeBarChart(frame_progress_day, dailies, "days","num_day", "steelblue", {label: [ {data: ["num_day"]} ]})
    makeBarChart(frame_progress_bad, dailies, "days","num_bad", "#6521A0", {label: [ {data: ["num_bad"]} ]})

  @plotLayerDays = (data) ->
    #{"dataID":2,"layerID":37,"wireID":2,"tBase":"80","density":3.359e-09,"date":"2015/06/12","freq":49.89,"tens":78.6}
    layerData = _.groupBy(data, (d) -> parseInt(d.layerID))
    console.log(layerData)
    layerNumbers = _.keys(layerData)
    xmin = _.min(layerNumbers, _.identity)
    xmax = _.max(layerNumbers, _.identity)
    xmin = parseInt(xmin)
    xmax = parseInt(xmax)
    #console.log("layerNumbers "+ layerNumbers);
    #console.log("xmin "+ xmin);
    #console.log("xmax "+ xmax);
    #mydata = _.range(1,40).map((d)-> {layerID: d, num_days: 0})
    mydata = ({layerID: d, num_days: 0} for d in [1..40])
    #console.log(mydata);
    _.each layerData, (v, layerID) -> 
       days = _.groupBy(v, (d2) -> d3.date)
       #console.log(layerID)
       #console.log(days)
       #console.log(mydata[layerID-1])
       num_days = _.keys(days).length
       #console.log(_.keys(days).length)
       mydata[layerID-1].layerID = layerID
       mydata[layerID-1].num_days = num_days
           
    #console.log(JSON.stringify(mydata))
    svg = append_svg("#menu_progress #layer_days")
    #console.log("xdomain->")
    #//var xdomain = _.range(xmin,xmax+1)
    #xdomain = _.range(0,40)
    xdomain = (x for x in [0..40])
    #//console.log(xmax+1)
    #//console.log(xdomain)
    #//console.log(mydata)
    ydomain = [0, 10]
    #xaxis_tickValues = _.range(0,40,5)
    xaxis_tickValues = (x for x in [0..40] by 5)
    frame = make_frame(svg, "layer_id", "days", xdomain, ydomain, {xaxis_type: "roundBands", xaxis_tickValues: xaxis_tickValues})
    makeBarChart(frame, mydata, "layerID","num_days", "#A8BE62", {label: [ {data: ["layerID"], prefix: 'layer_id '}, {data: ["num_days"], postfix: ' days'} ]})
       
class Load
  @plot: (dailies) ->
    xdomain = d3.extent(dailies, (d) ->  d.utime)
    labelA = ((d) -> d.date)
  
    # Wire
    ydomain_wire = [0, dailies[dailies.length-1].wire_tension_kg]
    #/console.log(ydomain_wire)
    svg_wire = append_svg("#menu_load_wire")
    frame_wire = make_frame(svg_wire, "date", "loading of wires (kg)", xdomain, ydomain_wire, {xaxis_type: "time"})
    makeScatterPlot(frame_wire, dailies, "utime", "wire_tension_kg", { stroke: "#ff1493", fill: "#ff69b4", stroke_width: "1px", line_stroke: "#ff1493" },[],
              { label: [ { data: [ labelA, (d) -> "#{d.wire_tension_kg.toFixed(1) kg}" ], separator:' '} ]})
  

class Endplate
  @plot: (data, current) ->
    svg = d3.select("#menu_status #status").append("svg").attr({width:w, height:h})
    svg.selectAll("circle")
       .data(holes)
       .enter()
       .append("circle")
       .attr("cx", ((d) -> d.x/diam*w*0.9 + w/2.0))
       .attr("cy", ((d) -> -d.y/diam*h*0.9 + h/2.0))
       .attr("r", 0.5)
       .attr("flll", "gray")

    svg.selectAll("circle.hoge")
        .data(data)
        .enter()
        .append("circle")
        #.on("mouseover", (d) -> d3.select(this).attr("fill", "orange"))
        #.on("mouseout", (d) -> d3.select(this).attr("fill", "red") )
        #.on "click", (d) ->
        #         rs = d3.select(this).attr("r");
        #         d3.select("body").select("p").text(rs);
        .attr("cx", (d) -> +get_xypos(d.layerID, d.wireID, numWires[d.layerID-1])["x"]/diam*w*0.9 + w/2)
        .attr("cy", (d) -> -get_xypos(d.layerID, d.wireID, numWires[d.layerID-1])["y"]/diam*h*0.9 + h/2)
        .attr("r",  (d) -> 0)
        .transition()
        .delay((d,i) -> (1000/data.length)*i)
        .duration(3000)
        .attr("r", (d) -> 1.5)
        .attr("stroke", (d) -> (d.tbase=="50")?"#f8d7d7":"#bdd0f4")
        .attr("fill",   (d) -> if (d.tBase=="50") then "#ed5454" else "#3874e3")
        .attr("stroke_width", "1px")
        .each "end", (current) ->
            #r1 = parseFloat(current_num_layers/39.0*100).toFixed(0)
            r2 = parseFloat(current.num_sum/numTotalWires*100).toFixed(0)
            r3 = parseFloat(current.num_sense/4986*100).toFixed(0)
            r4 = parseFloat(current.num_field/14562*100).toFixed(0)
  
            #Show status
            texts=[
              "Days: #{current.days} (#{current.date})"
              #"Layer: "+r1+"% ("+current_num_layers+"/39)",
              "Wire:  #{r2}% (#{current.num_sum}/#{numTotalWires})"
              "Sense: #{r3}% (#{current.num_sense}/4986)"
              "Field: #{r4}% (#{current.num_field}/14562)"]
  
            svg.selectAll("text")
               .data(texts)
               .enter()
               .append('text')
               .text((txt) -> txt)
               .attr("x",(_, i) -> w*1.1/3.0)
               .attr("y", (_, i) -> h/2.5+(i+1.0)*25)
               .attr("font-family", "HelveticaNeue-Light")
               .attr("font-style", "italic")
               .attr("font-size", (_,i) -> if i==0 then "20px" else "20px" )
               .attr("text-anchor", (_,i) -> if i==0 then "start" else "start")
               .attr("fill", "none")
               .transition()
               .duration(1000)
               .ease("linear")
               .attr("fill", (_, i) -> if i==2 then "#ed5454" else if i==3 then "#3874e3" else "black")
               

class LayerSelection
  @plot: (data) ->
    @layerCheckList = (true for i in [0..39])
    #@layerCheckList = _.map(_.range(39), (i) -> true)
    
    layer_selection = ({layerid: i} for i in [0..40])
    
    #console.log("layer_selection");
    #console.log(layer_selection);
    labels = d3.select("#menu_tension")
               .append("div")
               .html("LayerID")
               .attr("id","layer_selection")
               .selectAll(".test")
               .data(layer_selection)
               .enter()
               .append("label")
               .attr("class", "label_id_layers")
               .text((d) -> d.layerid)
               .insert("input")
               .attr("type", "checkbox")
               .property("checked", true)
               .attr("id", (d) -> "id_layer_" + d.layerid)
               .attr("value", (d) -> d.layerid)
               .on "click", (d) -> 
                 chk = d3.select(this).property("checked")
                 msg = "layer #{d.layerid} -> #{chk}"
                 @layerCheckList[d.layerid-1] = chk
                 #console.log(msg);
                 Tension.plot(data, @layerCheckList)
                 TensionHistogram.plot(data, "sense")
                 TensionHistogram.plot(data, "field")
  
     p = d3.select("#menu_tension")
           .append("p")
           .attr("id","layer_selection")
  
     texts = ["checkall","uncheckall"]
     p.insert("select")
      .attr("id","layer_selection2")
      .selectAll(".dummy")
      .data(texts)
      .enter()
      .append("option")
      .attr("value", (d) -> d)
      .append("text").text((d) -> d)
  
     d3.select("#layer_selection2")
       .on "change", (d) ->
         val = d3.select(this).property("value")
         #console.log("val -> "+ val)
         chk = if (val=="checkall") then true else false
         labels.property("checked",chk)
         @layerCheckList = (chk for i in [0...39])
         #console.log("changed")
         Tension.plot(data, @layerCheckList)
         TensionHistogram.plot(data,"sense")
         TensionHistogram.plot(data,"field")


class Tension
  constructor: (data) ->
    xdomain_tension = [0, d3.max(data, (d) -> d.wireID)]
    ydomain_tension = [0, d3.max(data, (d) -> d.tens)]
    svg_tension = append_svg("#menu_tension")
    frame_tension = make_frame(svg_tension, "wire_id", "tension (g)", xdomain_tension, ydomain_tension, {xaxis_type: "linear"})
    LayerSelection.plot(data)

  @plot: (data, layerCheckList) ->
    xmin = d3.min(data, (d) -> d.wireID)
    xmax = d3.max(data, (d) -> d.wireID)
    makeLine(frame_tension, "tension_limit_sense", [ { x:xmin, y: 45}, {x:xmax, y: 45} ])
    makeLine(frame_tension, "tension_limit_sense", [ { x:xmin, y: 55}, {x:xmax, y: 55} ])
    makeLine(frame_tension, "tension_limit_field", [ { x:xmin, y: 72}, {x:xmax, y: 72} ])
    makeLine(frame_tension, "tension_limit_field", [ { x:xmin, y: 88}, {x:xmax, y: 88} ])
  
    #console.log(layerCheckList);
    data_select = _.filter data, (d) ->
      #console.log(layerCheckList[d.layerID-1])
      layerCheckList[d.layerID-1]
  
    #console.log("data->");
    #console.log(data);
    #console.log("data_select-> " + data_select.length);
    #console.log(data_select);
    makeScatterPlot frame_tension, data_select, "wireID", "tens", 
                {
                  stroke: (d) -> if (d.tBase==80) then "#3874e3" else "#ed5454"
                  fill:   (d) -> if (d.tBase==80) then "#bdd0f4" else "#f8d7d7"
                  stroke_width: (d) -> if (d.tens<d.tBase*0.9 || d.tens>d.tBase*1.1) then "1px" else "0px"
                },
                [
                  {label:"sense", stroke:"#ed5454", fill:"#f8d7d7", ypos:"15"}
                  {label:"field", stroke:"#3874e3", fill:"#bdd0f4", ypos:"30"}
                ],
                {label: [ {data: ["date"] }
                          {data: ["layerID", "wireID"], separator: '-'}
                          {data: ["tens"], postfix:' g'} ]
                }


class TensionHistogram 
  constuctor: ->
    @svg_tension_hist = {}
    @frame_tension_hist = {}
    @first_call_hist = {"sense":true, "field":true}

  @plot: (data, sense_or_field) ->
    #console.log("plotTensionHistogram");
    # count entries
    nx = 20
    if sense_or_field=="sense"
      xmin = 40
      xmax = 60
    else
      xmin = 68
      xmax = 88

    xstep = (xmax - xmin)/nx
    xdomain = (x for x in [xmin..xmax] by xstep)
    tick_list = (tick for tick in [0..nx] by 2)
    xaxis_tickValues = (xdomain[tick] for tick in tick_list)
    #xdomain = _.range(xmin, xmax, xstep)
    #tick_list = _.range(0, nx, 2)
    #xaxis_tickValues = _.map(tick_list, (d) -> xdomain[d])
    #console.log("xdomain");
    #console.log(xdomain);
    #console.log("xaxis_tickValues");
    #console.log(xaxis_tickValues);

    # test data
    #data = [
    #   {tens:70},
    #   {tens:72},
    #   {tens:78},
    #   {tens:73},
    #   {tens:71},
    #   {tens:70},
    #   {tens:85},
    #   {tens:81}
    #];
    data_select = _.filter data, (d) ->
      is_sense = d.tBase=="50"
      is_field = d.tBase=="80"
      if is_sense && sense_or_field isnt "sense"
        return false
        #console.log("is_sense " + is_sense + " d.tBase " + d.tBase);
      else if is_field && sense_or_field isnt "field"
        return false
        #console.log(layerCheckList[d.layerID-1]);
      else 
        return layerCheckList[d.layerID-1]

    entries = _.countBy(data_select, (d) -> Math.floor((d.tens - xmin)/xstep))
    bindatum = _.map(xdomain, (e, i) -> {itens: xdomain[i], ents: if e? then e else 0})

    ydomain = [0, d3.max(bindatum, (d) -> d.ents)]
    #console.log("xdomain");
    #console.log(xdomain);
    #console.log("entries");
    #console.log(entries);
    #console.log("bindatum");
    #console.log(bindatum);
    #console.log("ydomain");
    #console.log(ydomain);
    if first_call_hist[sense_or_field]
      d3.select("#menu_tension").append("div").attr("id","menu_tension_#{sense_or_field}")
      @svg_tension_hist[sense_or_field] = append_svg("#menu_tension_#{sense_or_field}")
      @first_call_hist[sense_or_field] = false

    @frame_tension_hist[sense_or_field] = make_frame(@svg_tension_hist[sense_or_field], "tension (g)", "#/g", xdomain, ydomain, {xaxis_type: "roundBands", xaxis_tickValues: xaxis_tickValues})
    makeBarChart(@frame_tension_hist[sense_or_field], bindatum, "itens","ents", (-> if (sense_or_field=="sense") then "#ed5454" else "#3874e3"), {label: [ {data: ["ents"]} ]})
    tension_mean = _.reduce(data_select, ((memo, d) -> memo + d.tens), 0) /data_select.length
    tension_rms =  _.reduce(data_select, ((memo, d) -> memo + Math.pow(d.tens-tension_mean,2)), 0) /data_select.length
    tension_rms = Math.sqrt(tension_rms)
    frac_rms = (tension_rms/tension_mean*100).toFixed(0)
    makeStatBox(frame_tension_hist[sense_or_field], w-250, 20, "Mean #{tension_mean.toFixed(2)} g")
    makeStatBox(frame_tension_hist[sense_or_field], w-250, 40, "Rms #{tension_rms.toFixed(2)} g (#{frac_rms} '%')")


$ ->
  $("#file").change ->
    console.log "called onFileInput"
    item = @files[0]
    reader = new FileReader()
    reader.onload = onFileLoad
    reader.readAsText(item)
    return

  onFileLoad = (e) -> 
    parser = new DOMParser()
    xmlDoc = parser.parseFromString(e.target.result, "text/xml")
    console.log xmlDoc
    return

  s3 = new S3()
  s3.getObject "stats/stats.json", (url) ->
    d3.json url, (error, dailies) ->
      console.log(dailies)

      Progress.plot(dailies)
      Load.plot(dailies)

      s3.getObject "csv/tension_bar.csv", (url) ->
       d3.csv url, (error, csv) ->
       TensionBar.plot(csv, dailies)

      s3.getObject "daily/current/data.json", (url) ->
        #json_name = "./daily/current/data.json";
        #{"dataID":2,"layerID":37,"wireID":2,"tBase":"80","density":3.359e-09,"date":"2015/06/12","freq":49.89,"tens":78.6}
        d3.json url, (error, data) ->
          Endplate.plot(data, dailies[dailies.length-1])
          Tension.plot(data)
          TensionHistogram.plot(data,"sense")
          TensionHistogram.plot(data,"field")
          Progress.plotLayerDays(data)


  s3.getObject "csv/dial_gauge.csv", (url) ->
     d3.csv url, (error, csv) ->
       DialGauge.plot(csv)
