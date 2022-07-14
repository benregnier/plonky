print(_VERSION)
print(package.cpath)
if not string.find(package.cpath,"/home/we/dust/code/plonky/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/plonky/lib/?.so"
end
local json=require("cjson")
-- local json=include("plonky/lib/json") -- todo load faster library
-- local lattice=require("lattice")
local lattice=include("plonky/lib/lattice")
local MusicUtil=require "musicutil"
local Formatters=require "formatters"

-- mx.samples Config

local mxsamples=nil
if util.file_exists(_path.code.."mx.samples") then
  mxsamples=include("mx.samples/lib/mx.samples")
end

-- Thebangs' Config

if util.file_exists(_path.code.."thebangs") then
  thebangs_exists=true
end

local Thebangs={}print(_VERSION)
print(package.cpath)
if not string.find(package.cpath,"/home/we/dust/code/plonky/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/plonky/lib/?.so"
end
local json=require("cjson")
-- local json=include("plonky/lib/json") -- todo load faster library
-- local lattice=require("lattice")
local lattice=include("plonky/lib/lattice")
local MusicUtil=require "musicutil"
local Formatters=require "formatters"

-- mx.samples Config

local mxsamples=nil
if util.file_exists(_path.code.."mx.samples") then
  mxsamples=include("mx.samples/lib/mx.samples")
end

-- Thebangs' Config

if util.file_exists(_path.code.."thebangs") then
  thebangs_exists=true
end

local Thebangs={}
Thebangs.options={}
Thebangs.options.algoNames={
   "square","square_mod1","square_mod2",
   "sinfmlp","sinfb",
   "reznoise",
   "klangexp","klanglin"
}

Thebangs.options.stealModes={
   "static","FIFO","LIFO","ignore"
}


-- Molly's Config

local function format_ratio_to_one(param)
  return util.round(param:get(),0.01) .. ":1"
end

local function format_fade(param)
  local secs=param:get()
  local suffix=" in"
  if secs < 0 then
    secs=secs - specs.LFO_FADE.minval
    suffix=" out"
  end
  secs=util.round(secs,0.01)
  return math.abs(secs) .. " s" .. suffix
end

local specs={}
local options={}

options.OSC_WAVE_SHAPE={"Triangle","Saw","Pulse"}
specs.PW_MOD=controlspec.new(0,1,"lin",0,0.2,"")
options.PW_MOD_SRC={"LFO","Env 1","Manual"}
specs.FREQ_MOD_LFO=controlspec.UNIPOLAR
specs.FREQ_MOD_ENV=controlspec.BIPOLAR
specs.GLIDE=controlspec.new(0,5,"lin",0,0,"s")
specs.MAIN_OSC_LEVEL=controlspec.new(0,1,"lin",0,1,"")
specs.SUB_OSC_LEVEL=controlspec.UNIPOLAR
specs.SUB_OSC_DETUNE=controlspec.new(-5,5,"lin",0,0,"ST")
specs.NOISE_LEVEL=controlspec.new(0,1,"lin",0,0.1,"")
specs.HP_FILTER_CUTOFF=controlspec.new(10,20000,"exp",0,10,"Hz")
specs.LP_FILTER_CUTOFF=controlspec.new(20,20000,"exp",0,300,"Hz")
specs.LP_FILTER_RESONANCE=controlspec.new(0,1,"lin",0,0.1,"")
options.LP_FILTER_TYPE={"-12 dB/oct","-24 dB/oct"}
options.LP_FILTER_ENV={"Env-1","Env-2"}
specs.LP_FILTER_CUTOFF_MOD_ENV=controlspec.new(-1,1,"lin",0,0.25,"")
specs.LP_FILTER_CUTOFF_MOD_LFO=controlspec.UNIPOLAR
specs.LP_FILTER_TRACKING=controlspec.new(0,2,"lin",0,1,":1")
specs.LFO_FREQ=controlspec.new(0.05,20,"exp",0,5,"Hz")
options.LFO_WAVE_SHAPE={"Sine","Triangle","Saw","Square","Random"}
specs.LFO_FADE=controlspec.new(-15,15,"lin",0,0,"s")
specs.ENV_ATTACK=controlspec.new(0.002,5,"lin",0,0.01,"s")
specs.ENV_DECAY=controlspec.new(0.002,10,"lin",0,0.3,"s")
specs.ENV_SUSTAIN=controlspec.new(0,1,"lin",0,0.5,"")
specs.ENV_RELEASE=controlspec.new(0.002,10,"lin",0,0.5,"s")
specs.AMP=controlspec.new(0,11,"lin",0,0.5,"")
specs.AMP_MOD=controlspec.UNIPOLAR
specs.RING_MOD_FREQ=controlspec.new(10,300,"exp",0,50,"Hz")
specs.RING_MOD_FADE=controlspec.new(-15,15,"lin",0,0,"s")
specs.RING_MOD_MIX=controlspec.UNIPOLAR
specs.CHORUS_MIX=controlspec.new(0,1,"lin",0,0.8,"")


local Plonky={}

function Plonky:new(args)
  local m=setmetatable({},{__index=Plonky})
  local args=args==nil and {} or args
  m.debug=false -- args.debug TODO remove this
  m.grid_on=args.grid_on==nil and true or args.grid_on
  m.toggleable=args.toggleable==nil and false or args.toggleable

  m.scene="a"


  -- initiate mx samples
  if mxsamples~=nil then
    m.mx=mxsamples:new()
    m.instrument_list=m.mx:list_instruments()
  else
    m.mx=nil
    m.instrument_list={}
  end

  -- initiate the grid
  -- if you are using midigrid then first install in maiden with
  -- ;install https://github.com/jaggednz/midigrid
  -- and then comment out the following line:
  -- local grid=include("midigrid/lib/midigrid")
  m.g=grid.connect()
  m.grid64=m.g.cols==8
  m.grid64default=true
  m.grid_width=16
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- allow toggling
  m.kill_timer=0

  -- setup visual
  m.visual={}
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end
  
  --define grid display styles
  m.grid_note_display={"off","on"}
  m.grid_split={"8x8","4x16"}

  -- define num voices
  m.num_voices=8
  m.voice_set=0 -- the current voice set
  m.disable_menu_reload=false

  -- keep track of pressed buttons
  m.pressed_buttons={} -- keep track of where fingers press
  m.pressed_notes={} -- arp and patterns
  for i=0,m.num_voices/2-1 do
    m.pressed_notes[i*2]={}
  end

  -- debounce engine switching
  m.updateengine=0

  -- setup step sequencer
  m.voices={}
  local vs=0
  for i=1,m.num_voices do
    m.voices[i]={
      voice_set=vs,
      division=8,-- 8=quarter notes
      cluster={},
      pressed={},
      latched={},
      scale={},
      note_to_pos={},
      arp_last="",
      arp_step=1,
      record_steps={},
      record_step=1,
      record_step_adj=0,
      play_steps={},
      play_step=1,
      current_note="",
    }
    if i%2==0 then
      vs=vs+2
    end
  end

  -- setup lattice
  -- lattice
  -- for keeping time of all the divisions
  m.lattice=lattice:new({
    ppqn=64
  })
  m.timers={}
  m.divisions={1,2,4,6,8,12,16,24,32}
  m.division_names={"2","1","1/2","1/2t","1/4","1/4t","1/8","1/8t","1/16"}
  for _,division in ipairs(m.divisions) do
    m.timers[division]={}
    m.timers[division].lattice=m.lattice:new_pattern{
      action=function(t)
        m:emit_note(division,t)
      end,
    division=1/(division/2)}
  end


  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.1
  m.grid_refresh.event=function()
    if m.updateengine>0 then
      m.updateengine=m.updateengine-1
      if m.updateengine==0 then
        m:update_engine()
      end
    end
    if m.grid_on then
      m:grid_redraw()
    end
  end

  -- setup scale
  m.scale_names={}
  for i=1,#MusicUtil.SCALES do
    table.insert(m.scale_names,string.lower(MusicUtil.SCALES[i].name))
  end


  -- initiate midi connections
  m.device={}
  m.device_list={"disabled"}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name)
      table.insert(m.device_list,name)
      print("plonky midi: adding "..name.." to port "..dev.port)
      m.device[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
      }
      m.device[name].midi.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then
          do return end
        end
        -- tab.print(msg)
        -- OP-1 fix for transport
        if msg.type=='start' or msg.type=='continue' and name==m.device_list[params:get("midi_transport")] then
          print(name.." starting clock")
          m.lattice:hard_restart()
          for i=1,m.num_voices do
            params:set(i.."play",1)
          end
        elseif msg.type=="stop" and name==m.device_list[params:get("midi_transport")] then
          print(name.." stopping clock")
          for i=1,m.num_voices do
            params:set(i.."play",0)
          end
        elseif msg.type=="note_on" or msg.type=="note_off" then
          m:press_midi_note(name,msg.ch,msg.note,msg.vel,msg.type=="note_on")
        end
      end
    end
  end


  m:setup_params()
  m:build_scale()
  -- start up!
  m.grid_refresh:start()
  m.lattice:start()
  return m
end

function Plonky:update_voice_step(unity)
  self.voice_set=util.clamp(self.voice_set+2*unity,0,self.num_voices-2)
  -- if 1+self.voice_set~=params:get("voice") and 2+self.voice_set~=params:get("voice") then
  --   self.disable_menu_reload=true
  --   params:set("voice",self.voice_set+1)
  --   self.disable_menu_reload=false
  -- end
end

function Plonky:update_engine(name)
  if name==nil then
	  name=self.engine_options[params:get("mandoengine")]
  end
  print("loading "..name)
  self.engine_loaded=false
  engine.load(name,function()
    self.engine_loaded=true
    print("loaded "..name)
    -- write this engine as last used for next default on startup
    f=io.open(_path.data.."plonky/engine","w")
    f:write(params:get("mandoengine"))
    f:close()
    -- if you ever want to reduce number of voices
    -- if engine.name=="MxSamples" then
    --   print("setting max voices")
    --   self.mx:max_voices(40)
    -- end
  end)
  engine.name=name
  self:reload_params(params:get("voice"))
end

function Plonky:reload_params(v)
  for _,param_name in ipairs(self.param_names) do
    for i=1,self.num_voices do
      if i==v then
        params:show(i..param_name)
      else
        params:hide(i..param_name)
      end
    end
  end
  for eng,param_list in pairs(self.engine_params) do
    if string.sub(engine.name,1,2)==string.sub(eng,1,2) then
      for _,param_name in ipairs(param_list) do
        for i=1,self.num_voices do
          if i==v then
            params:show(i..param_name)
          else
            params:hide(i..param_name)
          end
        end
      end
    else
      for _,param_name in ipairs(param_list) do
        for j=1,self.num_voices do
          params:hide(j..param_name)
        end
      end
    end
  end
end

function Plonky:setup_params()
  self.engine_loaded=false
  self.engine_options={"PolyPerc"}
  if mxsamples~=nil then
    table.insert(self.engine_options,"MxSamples")
  end
  table.insert(self.engine_options,"MollyThePoly")
  if thebangs_exists==true then
    table.insert(self.engine_options,"Thebangs")
  end
  self.param_names={"scale","root","tuning","division","engine_enabled","midi","legato","crow","midichannel","midi in","midichannelin"}
  self.engine_params={}
  self.engine_params["MxSamples"]={"mx_instrument","mx_velocity","mx_amp","mx_pan","mx_release","mx_attack"}
  self.engine_params["PolyPerc"]={"pp_amp","pp_pw","pp_cut","pp_release"}
  self.engine_params["MollyThePoly"]={"osc_wave_shape","pulse_width_mod","pulse_width_mod_src","freq_mod_lfo","freq_mod_env","mtp_glide","main_osc_level","sub_osc_level","sub_osc_detune","noise_level","hp_filter_cutoff","lp_filter_cutoff","lp_filter_resonance","lp_filter_type","lp_filter_env","lp_filter_mod_env","lp_filter_mod_lfo","lp_filter_tracking","lfo_freq","lfo_fade","lfo_wave_shape","env_1_attack","env_1_decay","env_1_sustain","env_1_release","env_2_attack","env_2_decay","env_2_sustain","env_2_release","mtp_amp","mtp_amp_mod","ring_mod_freq","ring_mod_fade","ring_mod_mix","chorus_mix"}
  self.engine_params["Thebangs"]={"algo","steal_mode","steal_index","max_voices","b_attack","b_amp","b_pw","b_release","b_cutoff","b_gain","b_pan"}

  params:add_group("PLONKY",74*self.num_voices+5)
  params:add{type="number",id="voice",name="voice",min=1,max=self.num_voices,default=1,action=function(v)
    self:reload_params(v)
    if not self.disable_menu_reload then
      _menu.rebuild_params()
    end
  end}
  params:add_separator("outputs")
  for i=1,self.num_voices do
    -- midi out
    params:add{type="option",id=i.."engine_enabled",name="engine",options={"disabled","enabled"},default=2}
    params:add{type="option",id=i.."midi",name="midi out",options=self.device_list,default=1}
    params:add{type="number",id=i.."midichannel",name="midi out ch",min=1,max=16,default=1}
    params:add{type="option",id=i.."crow",name="crow/JF",options={"disabled","crow out 1+2","crow out 3+4","crow ii JF"},default=1,action=function(v)
      if v==2 then
        crow.output[2].action="{to(5,0),to(0,0.25)}"
      elseif v==3 then
        crow.output[4].action="{to(5,0),to(0,0.25)}"
      elseif v==4 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end}
  end
  params:add_separator("inputs")
  for i=1,self.num_voices do
    params:add{type="option",id=i.."midi in",name="midi in",options=self.device_list,default=1}--i==1 and 2 or 1} -- TODO change this to 1
    params:add{type="number",id=i.."midichannelin",name="midi in ch",min=1,max=16,default=1}
  end
  params:add_separator("engine parameters")
  for i=1,self.num_voices do
    -- MxSamples parameters
    params:add{type="option",id=i.."mx_instrument",name="instrument",options=self.instrument_list,default=1}
    params:add{type="number",id=i.."mx_velocity",name="velocity",min=0,max=127,default=80}
    params:add{type="control",id=i.."mx_amp",name="amp",controlspec=controlspec.new(0,2,'lin',0.01,0.5,'amp',0.01/2)}
    params:add{type="control",id=i.."mx_pan",name="pan",controlspec=controlspec.new(-1,1,'lin',0,0)}
    params:add{type="control",id=i.."mx_attack",name="attack",controlspec=controlspec.new(0,10,'lin',0,0,'s')}
    params:add{type="control",id=i.."mx_release",name="release",controlspec=controlspec.new(0,10,'lin',0,2,'s')}
    -- PolyPerc parameters
    params:add{type="control",id=i.."pp_amp",name="amp",controlspec=controlspec.new(0,1,'lin',0,0.25,'')}
    params:add{type="control",id=i.."pp_pw",name="pw",controlspec=controlspec.new(0,100,'lin',0,50,'%')}
    params:add{type="control",id=i.."pp_release",name="release",controlspec=controlspec.new(0.1,3.2,'lin',0,1.2,'s')}
    params:add{type="control",id=i.."pp_cut",name="cutoff",controlspec=controlspec.new(50,5000,'exp',0,800,'hz')}
    -- MollyThePoly parameters
    params:add{type="option",id=i.."osc_wave_shape",name="Osc Wave Shape",options=options.OSC_WAVE_SHAPE,default=3}
    params:add{type="control",id=i.."pulse_width_mod",name="Pulse Width Mod",controlspec=specs.PW_MOD}
    params:add{type="option",id=i.."pulse_width_mod_src",name="Pulse Width Mod Src",options=options.PW_MOD_SRC}
    params:add{type="control",id=i.."freq_mod_lfo",name="Frequency Mod (LFO)",controlspec=specs.FREQ_MOD_LFO}
    params:add{type="control",id=i.."freq_mod_env",name="Frequency Mod (Env-1)",controlspec=specs.FREQ_MOD_ENV}
    params:add{type="control",id=i.."mtp_glide",name="Glide",controlspec=specs.GLIDE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."main_osc_level",name="Main Osc Level",controlspec=specs.MAIN_OSC_LEVEL}
    params:add{type="control",id=i.."sub_osc_level",name="Sub Osc Level",controlspec=specs.SUB_OSC_LEVEL}
    params:add{type="control",id=i.."sub_osc_detune",name="Sub Osc Detune",controlspec=specs.SUB_OSC_DETUNE}
    params:add{type="control",id=i.."noise_level",name="Noise Level",controlspec=specs.NOISE_LEVEL,action=engine.noiseLevel}
    params:add{type="control",id=i.."hp_filter_cutoff",name="HP Filter Cutoff",controlspec=specs.HP_FILTER_CUTOFF,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."lp_filter_cutoff",name="LP Filter Cutoff",controlspec=specs.LP_FILTER_CUTOFF,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."lp_filter_resonance",name="LP Filter Resonance",controlspec=specs.LP_FILTER_RESONANCE}
    params:add{type="option",id=i.."lp_filter_type",name="LP Filter Type",options=options.LP_FILTER_TYPE,default=2}
    params:add{type="option",id=i.."lp_filter_env",name="LP Filter Env",options=options.LP_FILTER_ENV}
    params:add{type="control",id=i.."lp_filter_mod_env",name="LP Filter Mod (Env)",controlspec=specs.LP_FILTER_CUTOFF_MOD_ENV}
    params:add{type="control",id=i.."lp_filter_mod_lfo",name="LP Filter Mod (LFO)",controlspec=specs.LP_FILTER_CUTOFF_MOD_LFO}
    params:add{type="control",id=i.."lp_filter_tracking",name="LP Filter Tracking",controlspec=specs.LP_FILTER_TRACKING,formatter=format_ratio_to_one}
    params:add{type="control",id=i.."lfo_freq",name="LFO Frequency",controlspec=specs.LFO_FREQ,formatter=Formatters.format_freq}
    params:add{type="option",id=i.."lfo_wave_shape",name="LFO Wave Shape",options=options.LFO_WAVE_SHAPE}
    params:add{type="control",id=i.."lfo_fade",name="LFO Fade",controlspec=specs.LFO_FADE,formatter=format_fade,action=function(v)
      if v<0 then v=specs.LFO_FADE.minval-0.00001+math.abs(v) end
        engine.lfoFade(v)
      end}
    params:add{type="control",id=i.."env_1_attack",name="Env-1 Attack",controlspec=specs.ENV_ATTACK,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_1_decay",name="Env-1 Decay",controlspec=specs.ENV_DECAY,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_1_sustain",name="Env-1 Sustain",controlspec=specs.ENV_SUSTAIN}
    params:add{type="control",id=i.."env_1_release",name="Env-1 Release",controlspec=specs.ENV_RELEASE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_attack",name="Env-2 Attack",controlspec=specs.ENV_ATTACK,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_decay",name="Env-2 Decay",controlspec=specs.ENV_DECAY,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_sustain",name="Env-2 Sustain",controlspec=specs.ENV_SUSTAIN}
    params:add{type="control",id=i.."env_2_release",name="Env-2 Release",controlspec=specs.ENV_RELEASE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."mtp_amp",name="Amp",controlspec=specs.AMP}
    params:add{type="control",id=i.."mtp_amp_mod",name="Amp Mod (LFO)",controlspec=specs.AMP_MOD}
    params:add{type="control",id=i.."ring_mod_freq",name="Ring Mod Frequency",controlspec=specs.RING_MOD_FREQ,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."ring_mod_fade",name="Ring Mod Fade",controlspec=specs.RING_MOD_FADE,formatter=format_fade,action=function(v)
      if v<0 then v=specs.RING_MOD_FADE.minval-0.00001+math.abs(v) end
        engine.ringModFade(v)
      end}
    params:add{type="control",id=i.."ring_mod_mix",name="Ring Mod Mix",controlspec=specs.RING_MOD_MIX}
    params:add{type="control",id=i.."chorus_mix",name="Chorus Mix",controlspec=specs.CHORUS_MIX}
    -- Thebangs parameters
    params:add{type="option",id=i.."algo",name="algo",default=1,options=Thebangs.options.algoNames}
    params:add{type="option",id=i.."steal_mode",name="steal mode",default=2,options=Thebangs.options.stealModes}
    params:add{type="number",id=i.."steal_index",name="steal index",min=0,max=32,default=0}
    params:add{type="number",id=i.."max_voices",name="max voices",min=1,max=32,default=32}
    params:add{type="control",id=i.."b_attack",name="attack",controlspec=controlspec.new(0.0001,1,'exp',0,0.01,'')}
    params:add{type="control",id=i.."b_amp",name="amp",controlspec=controlspec.new(0,1,'lin',0,0.5,'')}
    params:add{type="control",id=i.."b_pw",name="pw",controlspec=controlspec.new(0,100,'lin',0,50,'%')}
    params:add{type="control",id=i.."b_release",name="release",controlspec=controlspec.new(0.1,3.2,'lin',0,1.2,'s')}
    params:add{type="control",id=i.."b_cutoff",name="cutoff",controlspec=controlspec.new(50,5000,'exp',0,800,'hz')}
    params:add{type="control",id=i.."b_gain",name="gain",controlspec=controlspec.new(0,4,'lin',0,1,'')}
    params:add{type="control",id=i.."b_pan",name="pan",controlspec=controlspec.new(-1,1,'lin',0,0,'')}

  end

  params:add_separator("plonky")
  for i=1,self.num_voices do
    params:add{type="option",id=i.."scale",name="scale",options=self.scale_names,default=1,action=function(v)
      self:build_scale()
    end}
    params:add{type="number",id=i.."root",name="root",min=0,max=36,default=24,formatter=function(param)
      return MusicUtil.note_num_to_name(param:get(),true)
    end,action=function(v)
      self:build_scale()
    end}
    params:add{type="number",id=i.."tuning",name="string tuning",min=0,max=7,default=5,formatter=function(param)
      return "+"..param:get()
    end,action=function(v)
      self:build_scale()
    end}
    params:add{type="option",id=i.."division",name="division",options=self.division_names,default=7}
    params:add{type="control",id=i.."legato",name="legato",controlspec=controlspec.new(1,99,'lin',1,50,'%')}
    params:add{type="binary",id=i.."arp",name="arp",behavior="toggle",default=0}
    params:hide(i.."arp")
    params:add{type="binary",id=i.."latch",name="latch",behavior="toggle",default=0,action=function(v)
      if v==1 then
        -- load latched steps
        if params:get(i.."latch_steps")~="" and params:get(i.."latch_steps")~="[]" then
          self.voices[i].latched=json.decode(params:get(i.."latch_steps"))
        end
      end
    end}
    params:hide(i.."latch")
    params:add{type="binary",id=i.."mute_non_arp",name="mute non-arp",behavior="toggle",default=0}
    params:hide(i.."mute_non_arp")
    params:add{type="binary",id=i.."record",name="record pattern",behavior="toggle",default=0,action=function(v)
      if v==1 then
        self.voices[i].record_step=0
        self.voices[i].record_step_adj=0
        self.voices[i].record_steps={}
        self.voices[i].cluster={}
      elseif v==0 and self.voices[i].record_step>0 then
        if self.debug then
          print(json.encode(self.voices[i].record_steps))
        end
        params:set(i.."play_steps",json.encode(self.voices[i].record_steps))
      end
    end}
    params:hide(i.."record")
    params:add{type="binary",id=i.."play",name="play",behavior="toggle",action=function(v)
      if v==1 then
        if params:get(i.."play_steps")~="[]" and params:get(i.."play_steps")~="" then
          if self.debug then print("playing "..i) end
          self.voices[i].play_steps=json.decode(params:get(i.."play_steps"))
          self.voices[i].play_step=0
        else
          params:set(i.."play",0)
        end
      else
        print("stopping "..i)
      end
    end}
    params:hide(i.."play")
    params:add_text(i.."play_steps",i.."play_steps","")
    params:hide(i.."play_steps")
    params:add_text(i.."latch_steps",i.."latch_steps","[]")
    params:hide(i.."latch_steps")
  end
  params:add{type="option",id="mandoengine",name="engine",options=self.engine_options,action=function()
    self.updateengine=10
  end}
  params:add{type="option",id="midi_transport",name="midi transport",options=self.device_list,default=1}
  params:add{type="option",id="grid_note_display",name="grid note display",options=self.grid_note_display,default=1}
  params:add{type="option",id="grid_split",name="grid split",options=self.grid_split,default=1}
  -- read in the last used engine as the default
  if util.file_exists(_path.data.."plonky/engine") then
    local f=io.open(_path.data.."plonky/engine","rb")
    local content=f:read("*all")
    f:close()
    print(content)
    local last_engine=tonumber(content)
    if last_engine~=nil then
    	params:set("mandoengine",last_engine)
    end
  end

  self:reload_params(1)
  self:update_engine()
end

function Plonky:reset_toggles()
  print("resetting toggles")
  for i=1,self.num_voices do
    params:set(i.."play",0)
    params:set(i.."mute_non_arp",0)
    params:set(i.."record",0)
    params:set(i.."arp",0)
    params:set(i.."latch",0)
  end
end

function Plonky:build_scale()
  for i=1,self.num_voices do
    self.voices[i].scale=MusicUtil.generate_scale_of_length(params:get(i.."root"),self.scale_names[params:get(i.."scale")],168)
    self.voices[i].note_to_pos={}
    -- determine the transformation between midi notes and grid
    if params:get("grid_split") == 1 then
      for j=1,8 do
        for k=1,8 do
          local k_=k
          if i%2==0 then
            k_=k_+8
          end
          local note=self:get_note_from_pos(i,j,k_)
          if note~=nil then
            if self.voices[i].note_to_pos[note]==nil then
              self.voices[i].note_to_pos[note]={}
            end
            table.insert(self.voices[i].note_to_pos[note],{j,k_})
          end
        end
      end
    else
      for j=1,4 do
        for k=1,16 do
          local j_=j
          if i%2==0 then
            j_=j_+4
          end
          local note=self:get_note_from_pos(i,j_,k) --this section edited
          if note~=nil then
            if self.voices[i].note_to_pos[note]==nil then
              self.voices[i].note_to_pos[note]={}
            end
            table.insert(self.voices[i].note_to_pos[note],{j_,k})
          end
        end
      end
    end
  end
  print("scale start: "..self.voices[1].scale[1])
  print("scale start: "..self.voices[2].scale[1])
end

function Plonky:toggle_grid64_side()
  self.grid64default=not self.grid64default
end

function Plonky:toggle_grid(on)
  if on==nil then
    self.grid_on=not self.grid_on
  else
    self.grid_on=on
  end
  if self.grid_on then
    self.g=grid.connect()
    self.g.key=function(x,y,z)
      print("plonky grid: ",x,y,z)
      if self.grid_on then
        self:grid_key(x,y,z)
      end
    end
  else
    if self.toggle_callback~=nil then
      self.toggle_callback()
    end
  end
end

function Plonky:set_toggle_callback(fn)
  self.toggle_callback=fn
end

function Plonky:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end


function Plonky:emit_note(division,step)
  local update=false
  for i=1,self.num_voices do
    if params:get(i.."play")==1 and self.divisions[params:get(i.."division")]==division then
      local num_steps=#self.voices[i].play_steps
      self.voices[i].play_step=self.voices[i].play_step+1
      if self.debug then
        print("playing step "..self.voices[i].play_step.."/"..num_steps)
      end
      if self.voices[i].play_step>num_steps then
        self.voices[i].play_step=1
      end
      local ind=self.voices[i].play_step
      local ind2=self.voices[i].play_step+1
      if ind2>num_steps then
        ind2=1
      end
      local rcs=self.voices[i].play_steps[ind]
      local rcs_next=self.voices[i].play_steps[ind2]
      if rcs~=nil and rcs_next~=nil then
        if rcs[1]~="-" and rcs[1]~="." then
          self.voices[i].play_last={}
          for _,key in ipairs(rcs) do
            local row,col=key:match("(%d+),(%d+)")
            row=tonumber(row)
            col=tonumber(col)
            self:press_note(self.voices[i].voice_set,row,col,true)
            table.insert(self.voices[i].play_last,{row,col})
          end
        end
        if rcs_next[1]~="-" and self.voices[i].play_last~=nil then
          clock.run(function()
            local play_last=self.voices[i].play_last
            clock.sleep(clock.get_beat_sec()/(division/2)*params:get(i.."legato")/100)
            for _,rc in ipairs(play_last) do
              self:press_note(self.voices[i].voice_set,rc[1],rc[2],false)
            end
            self.voices[i].play_last=nil
          end)
        end
        update=true
      end
    end
    if params:get(i.."arp")==1 and self.divisions[params:get(i.."division")]==division then
      local keys={}
      local keys_len=0
      if params:get(i.."latch")==1 then
        keys=self.voices[i].latched
        keys_len=#keys
      else
        keys,keys_len=self:get_keys_sorted_by_value(self.voices[i].pressed)
      end
      if keys_len>0 then
        local key=keys[1]
        local key_next=keys[2]
        if keys_len>1 then
          key=keys[(self.voices[i].arp_step)%keys_len+1]
          key_next=keys[(self.voices[i].arp_step+1)%keys_len+1]
        end
        local row,col=key:match("(%d+),(%d+)")
        row=tonumber(row)
        col=tonumber(col)
        self:press_note(self.voices[i].voice_set,row,col,true)
        clock.run(function()
          clock.sleep(clock.get_beat_sec()/(division/2)*params:get(i.."legato")/100)
          self:press_note(self.voices[i].voice_set,row,col,false)
        end)
        self.voices[i].arp_step=self.voices[i].arp_step+1
      end
      update=true
    end
  end
  if update then
    self:grid_redraw()
    redraw()
  end
end


function Plonky:get_visual()
  -- clear visual,decaying the notes
  for row=1,8 do
    for col=1,self.grid_width do
      if self.visual[row][col]>0 then
        self.visual[row][col]=self.visual[row][col]-1
        if self.visual[row][col]<0 then
          self.visual[row][col]=0
        end
      end
    end
  end

  local voice_pair={1+self.voice_set,2+self.voice_set}

  -- show latched
  for i=voice_pair[1],voice_pair[2] do
    local intensity=2
    if params:get(i.."latch")==1 then
      intensity=10
    end
    for _,k in ipairs(self.voices[i].latched) do
      local row,col=k:match("(%d+),(%d+)")
      if self.visual[tonumber(row)][tonumber(col)]==0 then
        self.visual[tonumber(row)][tonumber(col)]=intensity
      end
    end
  end

  -- illuminate currently pressed buttons
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=10
  end

  -- illuminate currently pressed notes
  for k,_ in pairs(self.pressed_notes[self.voice_set]) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=10
  end
  -- finger pressed notes
  for i=voice_pair[1],voice_pair[2] do
    self.voices[i].current_note=""
    for _,k in ipairs(self:get_keys_sorted_by_value(self.voices[i].pressed)) do
      local row,col=k:match("(%d+),(%d+)")
      row=tonumber(row)
      col=tonumber(col)
      self.visual[row][col]=15
      local note=self:get_note_from_pos(i,row,col)
      self.voices[i].current_note=self.voices[i].current_note.." "..MusicUtil.note_num_to_name(note,true)
    end
  end



  return self.visual
end

function Plonky:record_add_rest_or_legato(voice)
  if params:get(voice.."record")==0 then
    do return end
  end
  local wtd="." -- rest
  if self.debug then
    print("cluster ",json.encode(self.voices[voice].cluster))
    print("record_steps ",json.encode(self.voices[voice].record_steps))
  end

  if next(self.voices[voice].cluster)~=nil then
    wtd="-"
    self.voices[voice].record_steps[self.voices[voice].record_step]=self.voices[voice].cluster
    self.voices[voice].cluster={}
  elseif next(self.voices[voice].record_steps)~=nil and self.voices[voice].record_steps[#self.voices[voice].record_steps][1]=="-" and next(self.voices[voice].pressed)~=nil and next(self.voices[voice].cluster)==nil then
    wtd="-"
  end
  self:record_update_step(voice)
  self.voices[voice].record_steps[self.voices[voice].record_step]={wtd}
end

function Plonky:record_update_step(voice)
  if self.debug then
    print("record_update_step",json.encode(self.voices[voice].record_steps))
  end
  self.voices[voice].record_step=self.voices[voice].record_step+1

  -- check adjustment
  if self.voices[voice].record_step_adj==0 then do return end end
-- erase steps
  -- local last=self.voices[voice].record_steps[#self.voices[voice].record_steps]
  for i=self.voices[voice].record_step_adj,0 do
    self.voices[voice].record_steps[self.voices[voice].record_step+i]=nil
  end
  if self.voices[voice].record_steps==nil then
    self.voices[voice].record_steps={}
  end
  self.voices[voice].record_step=self.voices[voice].record_step+self.voices[voice].record_step_adj-1
  -- self.voices[voice].record_steps[self.voices[voice].record_step]=last
  self.voices[voice].record_step=self.voices[voice].record_step+1
  self.voices[voice].record_step_adj=0
  if self.debug then
    print("record_update_step (adj)",json.encode(self.voices[voice].record_steps))
  end
end

function Plonky:key_press(row,col,on)
  if self.grid64 and not self.grid64default then
    col=col+8
  end

  local ct=self:current_time()
  local rc=row..","..col
  if on then
    self.pressed_buttons[rc]=ct
  else
    self.pressed_buttons[rc]=nil
  end


  -- determine voice
  local voice=1+self.voice_set
  if params:get("grid_split") == 1 and col>8 then
    voice=2+self.voice_set
  elseif params:get("grid_split") == 2 and row>4 then
    voice=2+self.voice_set
  end

  if params:get("voice")~=voice and _menu.mode then
    params:set("voice",voice)
  end

  -- add to note cluster
  if on then
    self.voices[voice].pressed[rc]=ct
    if params:get(voice.."record")==1 and next(self.voices[voice].cluster)==nil then
      self:record_update_step(voice)
    end
    table.insert(self.voices[voice].cluster,rc)
  else
    self.voices[voice].pressed[rc]=nil
    local num_pressed=0
    for k,_ in pairs(self.voices[voice].pressed) do
      num_pressed=num_pressed+1
    end
    if num_pressed==0 then
      -- add the previous presses to note cluster
      if params:get(voice.."record")==1 then
        if next(self.voices[voice].cluster)~=nil then
          self.voices[voice].record_steps[self.voices[voice].record_step]=self.voices[voice].cluster
        end
        if self.debug then
          print(json.encode(self.voices[voice].record_steps))
        end
      else
        self.voices[voice].latched=self.voices[voice].cluster
        params:set(voice.."latch_steps",json.encode(self.voices[voice].cluster))
      end
      -- reset cluster
      self.voices[voice].cluster={}
    end
  end

  self:press_note(self.voice_set,row,col,on,true)
end

function Plonky:press_midi_note(name,channel,note,velocity,on)
  if self.debug then
    print("midi_note",name,channel,note,velocity,on)
  end
  -- WORK
  for i=1,self.num_voices do
    if i==self.voice_set+1 or i==self.voice_set+2 then
      if self.debug then
        print(i,name,self.device_list[params:get(i.."midi in")])
      end
      if name==self.device_list[params:get(i.."midi in")] and channel==params:get(i.."midichannelin") then
        local positions=self.voices[i].note_to_pos[note]
        if positions~=nil then
          self:key_press(positions[1][1],positions[1][2],on)
        end
      end
    end
  end
end

function Plonky:press_note(voice_set,row,col,on,is_finger)
  if on then
    self.pressed_notes[voice_set][row..","..col]=true
  else
    self.pressed_notes[voice_set][row..","..col]=nil
  end

  -- determine voice
  local voice=1+voice_set
  if params:get("grid_split") == 1 and col>8 then
    voice=2+voice_set
  elseif params:get("grid_split") == 2 and row>4 then
    voice=2+voice_set
  end


  -- determine note
  local note=self:get_note_from_pos(voice,row,col)
  if self.debug then
    print("voice "..voice.." press note "..MusicUtil.note_num_to_name(note,true))
  end

  -- determine if muted
  if is_finger~=nil and is_finger then
    if params:get(voice.."arp")==1 and params:get(voice.."mute_non_arp")==1 then
      do return end
    end
  end

  -- play from engine
  if not self.engine_loaded then
    do return end
  end
  if params:get(voice.."engine_enabled")==2 then
    if string.sub(engine.name,1,2)=="Mx" then
      if on then
        self.mx:on({
          name=self.instrument_list[params:get(voice.."mx_instrument")],
          midi=note,
          velocity=velocity or params:get(voice.."mx_velocity"),
          amp=params:get(voice.."mx_amp"),
          attack=params:get(voice.."mx_attack"),
          release=params:get(voice.."mx_release"),
          pan=params:get(voice.."mx_pan"),
        })
      else
        self.mx:off({name=self.instrument_list[params:get(voice.."mx_instrument")],midi=note})
      end
    elseif engine.name=="PolyPerc" then
      if on then
        engine.amp(params:get(voice.."pp_amp"))
        engine.release(params:get(voice.."pp_release"))
        engine.cutoff(params:get(voice.."pp_cut"))
        engine.pw(params:get(voice.."pp_pw")/100)
        engine.hz(MusicUtil.note_num_to_freq(note))
      end
    elseif engine.name=="MollyThePoly" then
      if on then
        engine.oscWaveShape(params:get(voice.."osc_wave_shape")-1)
        engine.pwMod(params:get(voice.."pulse_width_mod"))
        engine.pwModSource(params:get(voice.."pulse_width_mod_src")-1)
        engine.freqModEnv(params:get(voice.."freq_mod_env"))
        engine.freqModLfo(params:get(voice.."freq_mod_lfo"))
        engine.glide(params:get(voice.."mtp_glide"))
        engine.mainOscLevel(params:get(voice.."main_osc_level"))
        engine.subOscLevel(params:get(voice.."sub_osc_level"))
        engine.subOscDetune(params:get(voice.."sub_osc_detune"))
        engine.noiseLevel(params:get(voice.."noise_level"))
        engine.hpFilterCutoff(params:get(voice.."hp_filter_cutoff"))
        engine.lpFilterCutoff(params:get(voice.."lp_filter_cutoff"))
        engine.lpFilterResonance(params:get(voice.."lp_filter_resonance"))
        engine.lpFilterType(params:get(voice.."lp_filter_type")-1)
        engine.lpFilterCutoffEnvSelect(params:get(voice.."lp_filter_env")-1)
        engine.lpFilterCutoffModEnv(params:get(voice.."lp_filter_mod_env"))
        engine.lpFilterCutoffModLfo(params:get(voice.."lp_filter_mod_lfo"))
        engine.lpFilterTracking(params:get(voice.."lp_filter_tracking"))
        engine.lfoFreq(params:get(voice.."lfo_freq"))
        engine.lfoFade(params:get(voice.."lfo_fade"))
        engine.lfoWaveShape(params:get(voice.."lfo_wave_shape")-1)
        engine.env1Attack(params:get(voice.."env_1_attack"))
        engine.env1Decay(params:get(voice.."env_1_decay"))
        engine.env1Sustain(params:get(voice.."env_1_sustain"))
        engine.env1Release(params:get(voice.."env_1_release"))
        engine.env2Attack(params:get(voice.."env_2_attack"))
        engine.env2Decay(params:get(voice.."env_2_decay"))
        engine.env2Sustain(params:get(voice.."env_2_sustain"))
        engine.env2Release(params:get(voice.."env_2_release"))
        engine.amp(params:get(voice.."mtp_amp"))
        engine.ampMod(params:get(voice.."mtp_amp_mod"))
        engine.ringModFreq(params:get(voice.."ring_mod_freq"))
        engine.ringModFade(params:get(voice.."ring_mod_fade"))
        engine.ringModMix(params:get(voice.."ring_mod_mix"))
        engine.chorusMix(params:get(voice.."chorus_mix"))
        engine.noteOn(note,MusicUtil.note_num_to_freq(note),80) --hardcoding velocity
      else
        engine.noteOff(note)
      end
    elseif engine.name=="Thebangs" then
      if on then
        engine.algoIndex(params:get(voice.."algo"))
        engine.stealMode(params:get(voice.."steal_mode")-1)
        engine.stealIndex(params:get(voice.."steal_index"))
        engine.maxVoices(params:get(voice.."max_voices"))
        engine.attack(params:get(voice.."b_attack"))
        engine.amp(params:get(voice.."b_amp"))
        engine.pw(params:get(voice.."b_pw")/100)
        engine.release(params:get(voice.."b_release"))
        engine.cutoff(params:get(voice.."b_cutoff"))
        engine.gain(params:get(voice.."b_gain"))
        engine.pan(params:get(voice.."b_pan"))
        engine.hz(MusicUtil.note_num_to_freq(note))
      end
    end
  end

  -- play on midi device
  if params:get(voice.."midi")>1 then
    if on then
      if self.debug then
        print(note.." -> "..self.device_list[params:get(voice.."midi")])
      end
      self.device[self.device_list[params:get(voice.."midi")]].midi:note_on(note,velocity or 80,params:get(voice.."midichannel"))
    else
      self.device[self.device_list[params:get(voice.."midi")]].midi:note_off(note,velocity or 80,params:get(voice.."midichannel"))
    end
  end

  -- play on crow
  if params:get(voice.."crow")>1 and on then
    if params:get(voice.."crow")==2 then
      crow.output[1].volts=(note-60)/12
      crow.output[2].execute()
    elseif params:get(voice.."crow")==3 then
      crow.output[3].volts=(note-60)/12
      crow.output[4].execute()
    elseif params:get(voice.."crow")==4 then
      crow.ii.jf.play_note((note-60)/12,5)
    end
  end
end

function Plonky:get_cluster(voice)
  s=""
  for _,rc in ipairs(self.voices[voice].cluster) do
    local row,col=rc:match("(%d+),(%d+)")
    row=tonumber(row)
    col=tonumber(col)
    local note_name=rc
    if col~=nil and row~=nil then
      local note=self:get_note_from_pos(voice,row,col)
      note_name=MusicUtil.note_num_to_name(note,true)
    end
    s=s..note_name.." "
  end
  return s
end

function Plonky:get_note_from_pos(voice,row,col)
  if params:get("grid_split") == 1 then
    if voice%2==0 then
      col=col-8
    end
    return self.voices[voice].scale[(params:get(voice.."tuning")-1)*(col-1)+(9-row)] 
  else
    if voice%2==0 then
      row=row-4 --edited
    end
    return self.voices[voice].scale[(params:get(voice.."tuning")-1)*(5-row)+(col)]   
  end 
end

function Plonky:get_keys_sorted_by_value(tbl)
  sortFunction=function(a,b) return a<b end

  local keys={}
  local keys_length=0
  for key in pairs(tbl) do
    keys_length=keys_length+1
    table.insert(keys,key)
  end

  table.sort(keys,function(a,b)
    return sortFunction(tbl[a],tbl[b])
  end)

  return keys,keys_length
end

function Plonky:get_keys_sorted_by_key(tbl)
  sortFunction=function(a,b) return a<b end

  local keys={}
  local keys_length=0
  for key in pairs(tbl) do
    keys_length=keys_length+1
    table.insert(keys,key)
  end

  table.sort(keys,function(a,b)
    return sortFunction(a,b)
  end)

  return keys,keys_length
end

function Plonky:current_time()
  return clock.get_beat_sec()*clock.get_beats()
end

function Plonky:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  if self.grid64 then
    e=8
    if not self.grid64default then
      s=9
      e=16
      adj=-8
    end
  end
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      elseif params:get("grid_note_display") == 2 then                               
        local nvoice = 0
        if params:get("grid_split") == 1 and col<9 then
          nvoice = self.voice_set + 1
        elseif params:get("grid_split") == 2 and row<5 then
          nvoice = self.voice_set + 1
        else
          nvoice = self.voice_set + 2
        end
        --print(nvoice .. " " .. row .. " " .. col)
        local mnote = self:get_note_from_pos(nvoice,row,col)
        --print(mnote)
        local lnote = MusicUtil.note_num_to_name(mnote)
        local noteval = 0
        if lnote == "C" then
          noteval = 4
        elseif lnote == "D" or lnote == "E" or lnote == "F" or lnote == "G" or lnote == "A" or lnote == "B" then
          noteval = 2
        end
        self.g:led(col+adj,row,noteval)
      end
    end
  end
  self.g:refresh()
end

function Plonky:calculate_lfo(period_in_beats,offset)
  if period_in_beats==0 then
    return 1
  else
    return math.sin(2*math.pi*clock.get_beats()/period_in_beats+offset)
  end
end


return Plonky

Thebangs.options={}
Thebangs.options.algoNames={
   "square","square_mod1","square_mod2",
   "sinfmlp","sinfb",
   "reznoise",
   "klangexp","klanglin"
}

Thebangs.options.stealModes={
   "static","FIFO","LIFO","ignore"
}


-- Molly's Config

local function format_ratio_to_one(param)
  return util.round(param:get(),0.01) .. ":1"
end

local function format_fade(param)
  local secs=param:get()
  local suffix=" in"
  if secs < 0 then
    secs=secs - specs.LFO_FADE.minval
    suffix=" out"
  end
  secs=util.round(secs,0.01)
  return math.abs(secs) .. " s" .. suffix
end

local specs={}
local options={}

options.OSC_WAVE_SHAPE={"Triangle","Saw","Pulse"}
specs.PW_MOD=controlspec.new(0,1,"lin",0,0.2,"")
options.PW_MOD_SRC={"LFO","Env 1","Manual"}
specs.FREQ_MOD_LFO=controlspec.UNIPOLAR
specs.FREQ_MOD_ENV=controlspec.BIPOLAR
specs.GLIDE=controlspec.new(0,5,"lin",0,0,"s")
specs.MAIN_OSC_LEVEL=controlspec.new(0,1,"lin",0,1,"")
specs.SUB_OSC_LEVEL=controlspec.UNIPOLAR
specs.SUB_OSC_DETUNE=controlspec.new(-5,5,"lin",0,0,"ST")
specs.NOISE_LEVEL=controlspec.new(0,1,"lin",0,0.1,"")
specs.HP_FILTER_CUTOFF=controlspec.new(10,20000,"exp",0,10,"Hz")
specs.LP_FILTER_CUTOFF=controlspec.new(20,20000,"exp",0,300,"Hz")
specs.LP_FILTER_RESONANCE=controlspec.new(0,1,"lin",0,0.1,"")
options.LP_FILTER_TYPE={"-12 dB/oct","-24 dB/oct"}
options.LP_FILTER_ENV={"Env-1","Env-2"}
specs.LP_FILTER_CUTOFF_MOD_ENV=controlspec.new(-1,1,"lin",0,0.25,"")
specs.LP_FILTER_CUTOFF_MOD_LFO=controlspec.UNIPOLAR
specs.LP_FILTER_TRACKING=controlspec.new(0,2,"lin",0,1,":1")
specs.LFO_FREQ=controlspec.new(0.05,20,"exp",0,5,"Hz")
options.LFO_WAVE_SHAPE={"Sine","Triangle","Saw","Square","Random"}
specs.LFO_FADE=controlspec.new(-15,15,"lin",0,0,"s")
specs.ENV_ATTACK=controlspec.new(0.002,5,"lin",0,0.01,"s")
specs.ENV_DECAY=controlspec.new(0.002,10,"lin",0,0.3,"s")
specs.ENV_SUSTAIN=controlspec.new(0,1,"lin",0,0.5,"")
specs.ENV_RELEASE=controlspec.new(0.002,10,"lin",0,0.5,"s")
specs.AMP=controlspec.new(0,11,"lin",0,0.5,"")
specs.AMP_MOD=controlspec.UNIPOLAR
specs.RING_MOD_FREQ=controlspec.new(10,300,"exp",0,50,"Hz")
specs.RING_MOD_FADE=controlspec.new(-15,15,"lin",0,0,"s")
specs.RING_MOD_MIX=controlspec.UNIPOLAR
specs.CHORUS_MIX=controlspec.new(0,1,"lin",0,0.8,"")


local Plonky={}

function Plonky:new(args)
  local m=setmetatable({},{__index=Plonky})
  local args=args==nil and {} or args
  m.debug=false -- args.debug TODO remove this
  m.grid_on=args.grid_on==nil and true or args.grid_on
  m.toggleable=args.toggleable==nil and false or args.toggleable

  m.scene="a"


  -- initiate mx samples
  if mxsamples~=nil then
    m.mx=mxsamples:new()
    m.instrument_list=m.mx:list_instruments()
  else
    m.mx=nil
    m.instrument_list={}
  end

  -- initiate the grid
  -- if you are using midigrid then first install in maiden with
  -- ;install https://github.com/jaggednz/midigrid
  -- and then comment out the following line:
  -- local grid=include("midigrid/lib/midigrid")
  m.g=grid.connect()
  m.grid64=m.g.cols==8
  m.grid64default=true
  m.grid_width=16
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- allow toggling
  m.kill_timer=0

  -- setup visual
  m.visual={}
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end

  -- define num voices
  m.num_voices=8
  m.voice_set=0 -- the current voice set
  m.disable_menu_reload=false

  -- keep track of pressed buttons
  m.pressed_buttons={} -- keep track of where fingers press
  m.pressed_notes={} -- arp and patterns
  for i=0,m.num_voices/2-1 do
    m.pressed_notes[i*2]={}
  end

  -- debounce engine switching
  m.updateengine=0

  -- setup step sequencer
  m.voices={}
  local vs=0
  for i=1,m.num_voices do
    m.voices[i]={
      voice_set=vs,
      division=8,-- 8=quarter notes
      cluster={},
      pressed={},
      latched={},
      scale={},
      note_to_pos={},
      arp_last="",
      arp_step=1,
      record_steps={},
      record_step=1,
      record_step_adj=0,
      play_steps={},
      play_step=1,
      current_note="",
    }
    if i%2==0 then
      vs=vs+2
    end
  end

  -- setup lattice
  -- lattice
  -- for keeping time of all the divisions
  m.lattice=lattice:new({
    ppqn=64
  })
  m.timers={}
  m.divisions={1,2,4,6,8,12,16,24,32}
  m.division_names={"2","1","1/2","1/2t","1/4","1/4t","1/8","1/8t","1/16"}
  for _,division in ipairs(m.divisions) do
    m.timers[division]={}
    m.timers[division].lattice=m.lattice:new_pattern{
      action=function(t)
        m:emit_note(division,t)
      end,
    division=1/(division/2)}
  end


  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.1
  m.grid_refresh.event=function()
    if m.updateengine>0 then
      m.updateengine=m.updateengine-1
      if m.updateengine==0 then
        m:update_engine()
      end
    end
    if m.grid_on then
      m:grid_redraw()
    end
  end

  -- setup scale
  m.scale_names={}
  for i=1,#MusicUtil.SCALES do
    table.insert(m.scale_names,string.lower(MusicUtil.SCALES[i].name))
  end


  -- initiate midi connections
  m.device={}
  m.device_list={"disabled"}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name)
      table.insert(m.device_list,name)
      print("plonky midi: adding "..name.." to port "..dev.port)
      m.device[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
      }
      m.device[name].midi.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then
          do return end
        end
        -- tab.print(msg)
        -- OP-1 fix for transport
        if msg.type=='start' or msg.type=='continue' and name==m.device_list[params:get("midi_transport")] then
          print(name.." starting clock")
          m.lattice:hard_restart()
          for i=1,m.num_voices do
            params:set(i.."play",1)
          end
        elseif msg.type=="stop" and name==m.device_list[params:get("midi_transport")] then
          print(name.." stopping clock")
          for i=1,m.num_voices do
            params:set(i.."play",0)
          end
        elseif msg.type=="note_on" or msg.type=="note_off" then
          m:press_midi_note(name,msg.ch,msg.note,msg.vel,msg.type=="note_on")
        end
      end
    end
  end


  m:setup_params()
  m:build_scale()
  -- start up!
  m.grid_refresh:start()
  m.lattice:start()
  return m
end

function Plonky:update_voice_step(unity)
  self.voice_set=util.clamp(self.voice_set+2*unity,0,self.num_voices-2)
  -- if 1+self.voice_set~=params:get("voice") and 2+self.voice_set~=params:get("voice") then
  --   self.disable_menu_reload=true
  --   params:set("voice",self.voice_set+1)
  --   self.disable_menu_reload=false
  -- end
end

function Plonky:update_engine(name)
  if name==nil then
	  name=self.engine_options[params:get("mandoengine")]
  end
  print("loading "..name)
  self.engine_loaded=false
  engine.load(name,function()
    self.engine_loaded=true
    print("loaded "..name)
    -- write this engine as last used for next default on startup
    f=io.open(_path.data.."plonky/engine","w")
    f:write(params:get("mandoengine"))
    f:close()
    -- if you ever want to reduce number of voices
    -- if engine.name=="MxSamples" then
    --   print("setting max voices")
    --   self.mx:max_voices(40)
    -- end
  end)
  engine.name=name
  self:reload_params(params:get("voice"))
end

function Plonky:reload_params(v)
  for _,param_name in ipairs(self.param_names) do
    for i=1,self.num_voices do
      if i==v then
        params:show(i..param_name)
      else
        params:hide(i..param_name)
      end
    end
  end
  for eng,param_list in pairs(self.engine_params) do
    if string.sub(engine.name,1,2)==string.sub(eng,1,2) then
      for _,param_name in ipairs(param_list) do
        for i=1,self.num_voices do
          if i==v then
            params:show(i..param_name)
          else
            params:hide(i..param_name)
          end
        end
      end
    else
      for _,param_name in ipairs(param_list) do
        for j=1,self.num_voices do
          params:hide(j..param_name)
        end
      end
    end
  end
end

function Plonky:setup_params()
  self.engine_loaded=false
  self.engine_options={"PolyPerc"}
  if mxsamples~=nil then
    table.insert(self.engine_options,"MxSamples")
  end
  table.insert(self.engine_options,"MollyThePoly")
  if thebangs_exists==true then
    table.insert(self.engine_options,"Thebangs")
  end
  self.param_names={"scale","root","tuning","division","engine_enabled","midi","legato","crow","midichannel","midi in","midichannelin"}
  self.engine_params={}
  self.engine_params["MxSamples"]={"mx_instrument","mx_velocity","mx_amp","mx_pan","mx_release","mx_attack"}
  self.engine_params["PolyPerc"]={"pp_amp","pp_pw","pp_cut","pp_release"}
  self.engine_params["MollyThePoly"]={"osc_wave_shape","pulse_width_mod","pulse_width_mod_src","freq_mod_lfo","freq_mod_env","mtp_glide","main_osc_level","sub_osc_level","sub_osc_detune","noise_level","hp_filter_cutoff","lp_filter_cutoff","lp_filter_resonance","lp_filter_type","lp_filter_env","lp_filter_mod_env","lp_filter_mod_lfo","lp_filter_tracking","lfo_freq","lfo_fade","lfo_wave_shape","env_1_attack","env_1_decay","env_1_sustain","env_1_release","env_2_attack","env_2_decay","env_2_sustain","env_2_release","mtp_amp","mtp_amp_mod","ring_mod_freq","ring_mod_fade","ring_mod_mix","chorus_mix"}
  self.engine_params["Thebangs"]={"algo","steal_mode","steal_index","max_voices","b_attack","b_amp","b_pw","b_release","b_cutoff","b_gain","b_pan"}

  params:add_group("PLONKY",74*self.num_voices+5)
  params:add{type="number",id="voice",name="voice",min=1,max=self.num_voices,default=1,action=function(v)
    self:reload_params(v)
    if not self.disable_menu_reload then
      _menu.rebuild_params()
    end
  end}
  params:add_separator("outputs")
  for i=1,self.num_voices do
    -- midi out
    params:add{type="option",id=i.."engine_enabled",name="engine",options={"disabled","enabled"},default=2}
    params:add{type="option",id=i.."midi",name="midi out",options=self.device_list,default=1}
    params:add{type="number",id=i.."midichannel",name="midi out ch",min=1,max=16,default=1}
    params:add{type="option",id=i.."crow",name="crow/JF",options={"disabled","crow out 1+2","crow out 3+4","crow ii JF"},default=1,action=function(v)
      if v==2 then
        crow.output[2].action="{to(5,0),to(0,0.25)}"
      elseif v==3 then
        crow.output[4].action="{to(5,0),to(0,0.25)}"
      elseif v==4 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end}
  end
  params:add_separator("inputs")
  for i=1,self.num_voices do
    params:add{type="option",id=i.."midi in",name="midi in",options=self.device_list,default=1}--i==1 and 2 or 1} -- TODO change this to 1
    params:add{type="number",id=i.."midichannelin",name="midi in ch",min=1,max=16,default=1}
  end
  params:add_separator("engine parameters")
  for i=1,self.num_voices do
    -- MxSamples parameters
    params:add{type="option",id=i.."mx_instrument",name="instrument",options=self.instrument_list,default=1}
    params:add{type="number",id=i.."mx_velocity",name="velocity",min=0,max=127,default=80}
    params:add{type="control",id=i.."mx_amp",name="amp",controlspec=controlspec.new(0,2,'lin',0.01,0.5,'amp',0.01/2)}
    params:add{type="control",id=i.."mx_pan",name="pan",controlspec=controlspec.new(-1,1,'lin',0,0)}
    params:add{type="control",id=i.."mx_attack",name="attack",controlspec=controlspec.new(0,10,'lin',0,0,'s')}
    params:add{type="control",id=i.."mx_release",name="release",controlspec=controlspec.new(0,10,'lin',0,2,'s')}
    -- PolyPerc parameters
    params:add{type="control",id=i.."pp_amp",name="amp",controlspec=controlspec.new(0,1,'lin',0,0.25,'')}
    params:add{type="control",id=i.."pp_pw",name="pw",controlspec=controlspec.new(0,100,'lin',0,50,'%')}
    params:add{type="control",id=i.."pp_release",name="release",controlspec=controlspec.new(0.1,3.2,'lin',0,1.2,'s')}
    params:add{type="control",id=i.."pp_cut",name="cutoff",controlspec=controlspec.new(50,5000,'exp',0,800,'hz')}
    -- MollyThePoly parameters
    params:add{type="option",id=i.."osc_wave_shape",name="Osc Wave Shape",options=options.OSC_WAVE_SHAPE,default=3}
    params:add{type="control",id=i.."pulse_width_mod",name="Pulse Width Mod",controlspec=specs.PW_MOD}
    params:add{type="option",id=i.."pulse_width_mod_src",name="Pulse Width Mod Src",options=options.PW_MOD_SRC}
    params:add{type="control",id=i.."freq_mod_lfo",name="Frequency Mod (LFO)",controlspec=specs.FREQ_MOD_LFO}
    params:add{type="control",id=i.."freq_mod_env",name="Frequency Mod (Env-1)",controlspec=specs.FREQ_MOD_ENV}
    params:add{type="control",id=i.."mtp_glide",name="Glide",controlspec=specs.GLIDE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."main_osc_level",name="Main Osc Level",controlspec=specs.MAIN_OSC_LEVEL}
    params:add{type="control",id=i.."sub_osc_level",name="Sub Osc Level",controlspec=specs.SUB_OSC_LEVEL}
    params:add{type="control",id=i.."sub_osc_detune",name="Sub Osc Detune",controlspec=specs.SUB_OSC_DETUNE}
    params:add{type="control",id=i.."noise_level",name="Noise Level",controlspec=specs.NOISE_LEVEL,action=engine.noiseLevel}
    params:add{type="control",id=i.."hp_filter_cutoff",name="HP Filter Cutoff",controlspec=specs.HP_FILTER_CUTOFF,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."lp_filter_cutoff",name="LP Filter Cutoff",controlspec=specs.LP_FILTER_CUTOFF,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."lp_filter_resonance",name="LP Filter Resonance",controlspec=specs.LP_FILTER_RESONANCE}
    params:add{type="option",id=i.."lp_filter_type",name="LP Filter Type",options=options.LP_FILTER_TYPE,default=2}
    params:add{type="option",id=i.."lp_filter_env",name="LP Filter Env",options=options.LP_FILTER_ENV}
    params:add{type="control",id=i.."lp_filter_mod_env",name="LP Filter Mod (Env)",controlspec=specs.LP_FILTER_CUTOFF_MOD_ENV}
    params:add{type="control",id=i.."lp_filter_mod_lfo",name="LP Filter Mod (LFO)",controlspec=specs.LP_FILTER_CUTOFF_MOD_LFO}
    params:add{type="control",id=i.."lp_filter_tracking",name="LP Filter Tracking",controlspec=specs.LP_FILTER_TRACKING,formatter=format_ratio_to_one}
    params:add{type="control",id=i.."lfo_freq",name="LFO Frequency",controlspec=specs.LFO_FREQ,formatter=Formatters.format_freq}
    params:add{type="option",id=i.."lfo_wave_shape",name="LFO Wave Shape",options=options.LFO_WAVE_SHAPE}
    params:add{type="control",id=i.."lfo_fade",name="LFO Fade",controlspec=specs.LFO_FADE,formatter=format_fade,action=function(v)
      if v<0 then v=specs.LFO_FADE.minval-0.00001+math.abs(v) end
        engine.lfoFade(v)
      end}
    params:add{type="control",id=i.."env_1_attack",name="Env-1 Attack",controlspec=specs.ENV_ATTACK,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_1_decay",name="Env-1 Decay",controlspec=specs.ENV_DECAY,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_1_sustain",name="Env-1 Sustain",controlspec=specs.ENV_SUSTAIN}
    params:add{type="control",id=i.."env_1_release",name="Env-1 Release",controlspec=specs.ENV_RELEASE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_attack",name="Env-2 Attack",controlspec=specs.ENV_ATTACK,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_decay",name="Env-2 Decay",controlspec=specs.ENV_DECAY,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."env_2_sustain",name="Env-2 Sustain",controlspec=specs.ENV_SUSTAIN}
    params:add{type="control",id=i.."env_2_release",name="Env-2 Release",controlspec=specs.ENV_RELEASE,formatter=Formatters.format_secs}
    params:add{type="control",id=i.."mtp_amp",name="Amp",controlspec=specs.AMP}
    params:add{type="control",id=i.."mtp_amp_mod",name="Amp Mod (LFO)",controlspec=specs.AMP_MOD}
    params:add{type="control",id=i.."ring_mod_freq",name="Ring Mod Frequency",controlspec=specs.RING_MOD_FREQ,formatter=Formatters.format_freq}
    params:add{type="control",id=i.."ring_mod_fade",name="Ring Mod Fade",controlspec=specs.RING_MOD_FADE,formatter=format_fade,action=function(v)
      if v<0 then v=specs.RING_MOD_FADE.minval-0.00001+math.abs(v) end
        engine.ringModFade(v)
      end}
    params:add{type="control",id=i.."ring_mod_mix",name="Ring Mod Mix",controlspec=specs.RING_MOD_MIX}
    params:add{type="control",id=i.."chorus_mix",name="Chorus Mix",controlspec=specs.CHORUS_MIX}
    -- Thebangs parameters
    params:add{type="option",id=i.."algo",name="algo",default=1,options=Thebangs.options.algoNames}
    params:add{type="option",id=i.."steal_mode",name="steal mode",default=2,options=Thebangs.options.stealModes}
    params:add{type="number",id=i.."steal_index",name="steal index",min=0,max=32,default=0}
    params:add{type="number",id=i.."max_voices",name="max voices",min=1,max=32,default=32}
    params:add{type="control",id=i.."b_attack",name="attack",controlspec=controlspec.new(0.0001,1,'exp',0,0.01,'')}
    params:add{type="control",id=i.."b_amp",name="amp",controlspec=controlspec.new(0,1,'lin',0,0.5,'')}
    params:add{type="control",id=i.."b_pw",name="pw",controlspec=controlspec.new(0,100,'lin',0,50,'%')}
    params:add{type="control",id=i.."b_release",name="release",controlspec=controlspec.new(0.1,3.2,'lin',0,1.2,'s')}
    params:add{type="control",id=i.."b_cutoff",name="cutoff",controlspec=controlspec.new(50,5000,'exp',0,800,'hz')}
    params:add{type="control",id=i.."b_gain",name="gain",controlspec=controlspec.new(0,4,'lin',0,1,'')}
    params:add{type="control",id=i.."b_pan",name="pan",controlspec=controlspec.new(-1,1,'lin',0,0,'')}

  end

  params:add_separator("plonky")
  for i=1,self.num_voices do
    params:add{type="option",id=i.."scale",name="scale",options=self.scale_names,default=1,action=function(v)
      self:build_scale()
    end}
    params:add{type="number",id=i.."root",name="root",min=0,max=36,default=24,formatter=function(param)
      return MusicUtil.note_num_to_name(param:get(),true)
    end,action=function(v)
      self:build_scale()
    end}
    params:add{type="number",id=i.."tuning",name="string tuning",min=0,max=7,default=5,formatter=function(param)
      return "+"..param:get()
    end,action=function(v)
      self:build_scale()
    end}
    params:add{type="option",id=i.."division",name="division",options=self.division_names,default=7}
    params:add{type="control",id=i.."legato",name="legato",controlspec=controlspec.new(1,99,'lin',1,50,'%')}
    params:add{type="binary",id=i.."arp",name="arp",behavior="toggle",default=0}
    params:hide(i.."arp")
    params:add{type="binary",id=i.."latch",name="latch",behavior="toggle",default=0,action=function(v)
      if v==1 then
        -- load latched steps
        if params:get(i.."latch_steps")~="" and params:get(i.."latch_steps")~="[]" then
          self.voices[i].latched=json.decode(params:get(i.."latch_steps"))
        end
      end
    end}
    params:hide(i.."latch")
    params:add{type="binary",id=i.."mute_non_arp",name="mute non-arp",behavior="toggle",default=0}
    params:hide(i.."mute_non_arp")
    params:add{type="binary",id=i.."record",name="record pattern",behavior="toggle",default=0,action=function(v)
      if v==1 then
        self.voices[i].record_step=0
        self.voices[i].record_step_adj=0
        self.voices[i].record_steps={}
        self.voices[i].cluster={}
      elseif v==0 and self.voices[i].record_step>0 then
        if self.debug then
          print(json.encode(self.voices[i].record_steps))
        end
        params:set(i.."play_steps",json.encode(self.voices[i].record_steps))
      end
    end}
    params:hide(i.."record")
    params:add{type="binary",id=i.."play",name="play",behavior="toggle",action=function(v)
      if v==1 then
        if params:get(i.."play_steps")~="[]" and params:get(i.."play_steps")~="" then
          if self.debug then print("playing "..i) end
          self.voices[i].play_steps=json.decode(params:get(i.."play_steps"))
          self.voices[i].play_step=0
        else
          params:set(i.."play",0)
        end
      else
        print("stopping "..i)
      end
    end}
    params:hide(i.."play")
    params:add_text(i.."play_steps",i.."play_steps","")
    params:hide(i.."play_steps")
    params:add_text(i.."latch_steps",i.."latch_steps","[]")
    params:hide(i.."latch_steps")
  end
  params:add{type="option",id="mandoengine",name="engine",options=self.engine_options,action=function()
    self.updateengine=10
  end}
  params:add{type="option",id="midi_transport",name="midi transport",options=self.device_list,default=1}

  -- read in the last used engine as the default
  if util.file_exists(_path.data.."plonky/engine") then
    local f=io.open(_path.data.."plonky/engine","rb")
    local content=f:read("*all")
    f:close()
    print(content)
    local last_engine=tonumber(content)
    if last_engine~=nil then
    	params:set("mandoengine",last_engine)
    end
  end

  self:reload_params(1)
  self:update_engine()
end

function Plonky:reset_toggles()
  print("resetting toggles")
  for i=1,self.num_voices do
    params:set(i.."play",0)
    params:set(i.."mute_non_arp",0)
    params:set(i.."record",0)
    params:set(i.."arp",0)
    params:set(i.."latch",0)
  end
end

function Plonky:build_scale()
  for i=1,self.num_voices do
    self.voices[i].scale=MusicUtil.generate_scale_of_length(params:get(i.."root"),self.scale_names[params:get(i.."scale")],168)
    self.voices[i].note_to_pos={}
    -- determine the transformation between midi notes and grid
    for j=1,8 do
      for k=1,8 do
        local k_=k
        if i%2==0 then
          k_=k_+8
        end
        local note=self:get_note_from_pos(i,j,k_)
        if note~=nil then
          if self.voices[i].note_to_pos[note]==nil then
            self.voices[i].note_to_pos[note]={}
          end
          table.insert(self.voices[i].note_to_pos[note],{j,k_})
        end
      end
    end
  end
  print("scale start: "..self.voices[1].scale[1])
  print("scale start: "..self.voices[2].scale[1])
end

function Plonky:toggle_grid64_side()
  self.grid64default=not self.grid64default
end

function Plonky:toggle_grid(on)
  if on==nil then
    self.grid_on=not self.grid_on
  else
    self.grid_on=on
  end
  if self.grid_on then
    self.g=grid.connect()
    self.g.key=function(x,y,z)
      print("plonky grid: ",x,y,z)
      if self.grid_on then
        self:grid_key(x,y,z)
      end
    end
  else
    if self.toggle_callback~=nil then
      self.toggle_callback()
    end
  end
end

function Plonky:set_toggle_callback(fn)
  self.toggle_callback=fn
end

function Plonky:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end


function Plonky:emit_note(division,step)
  local update=false
  for i=1,self.num_voices do
    if params:get(i.."play")==1 and self.divisions[params:get(i.."division")]==division then
      local num_steps=#self.voices[i].play_steps
      self.voices[i].play_step=self.voices[i].play_step+1
      if self.debug then
        print("playing step "..self.voices[i].play_step.."/"..num_steps)
      end
      if self.voices[i].play_step>num_steps then
        self.voices[i].play_step=1
      end
      local ind=self.voices[i].play_step
      local ind2=self.voices[i].play_step+1
      if ind2>num_steps then
        ind2=1
      end
      local rcs=self.voices[i].play_steps[ind]
      local rcs_next=self.voices[i].play_steps[ind2]
      if rcs~=nil and rcs_next~=nil then
        if rcs[1]~="-" and rcs[1]~="." then
          self.voices[i].play_last={}
          for _,key in ipairs(rcs) do
            local row,col=key:match("(%d+),(%d+)")
            row=tonumber(row)
            col=tonumber(col)
            self:press_note(self.voices[i].voice_set,row,col,true)
            table.insert(self.voices[i].play_last,{row,col})
          end
        end
        if rcs_next[1]~="-" and self.voices[i].play_last~=nil then
          clock.run(function()
            local play_last=self.voices[i].play_last
            clock.sleep(clock.get_beat_sec()/(division/2)*params:get(i.."legato")/100)
            for _,rc in ipairs(play_last) do
              self:press_note(self.voices[i].voice_set,rc[1],rc[2],false)
            end
            self.voices[i].play_last=nil
          end)
        end
        update=true
      end
    end
    if params:get(i.."arp")==1 and self.divisions[params:get(i.."division")]==division then
      local keys={}
      local keys_len=0
      if params:get(i.."latch")==1 then
        keys=self.voices[i].latched
        keys_len=#keys
      else
        keys,keys_len=self:get_keys_sorted_by_value(self.voices[i].pressed)
      end
      if keys_len>0 then
        local key=keys[1]
        local key_next=keys[2]
        if keys_len>1 then
          key=keys[(self.voices[i].arp_step)%keys_len+1]
          key_next=keys[(self.voices[i].arp_step+1)%keys_len+1]
        end
        local row,col=key:match("(%d+),(%d+)")
        row=tonumber(row)
        col=tonumber(col)
        self:press_note(self.voices[i].voice_set,row,col,true)
        clock.run(function()
          clock.sleep(clock.get_beat_sec()/(division/2)*params:get(i.."legato")/100)
          self:press_note(self.voices[i].voice_set,row,col,false)
        end)
        self.voices[i].arp_step=self.voices[i].arp_step+1
      end
      update=true
    end
  end
  if update then
    self:grid_redraw()
    redraw()
  end
end


function Plonky:get_visual()
  -- clear visual,decaying the notes
  for row=1,8 do
    for col=1,self.grid_width do
      if self.visual[row][col]>0 then
        self.visual[row][col]=self.visual[row][col]-1
        if self.visual[row][col]<0 then
          self.visual[row][col]=0
        end
      end
    end
  end

  local voice_pair={1+self.voice_set,2+self.voice_set}

  -- show latched
  for i=voice_pair[1],voice_pair[2] do
    local intensity=2
    if params:get(i.."latch")==1 then
      intensity=10
    end
    for _,k in ipairs(self.voices[i].latched) do
      local row,col=k:match("(%d+),(%d+)")
      if self.visual[tonumber(row)][tonumber(col)]==0 then
        self.visual[tonumber(row)][tonumber(col)]=intensity
      end
    end
  end

  -- illuminate currently pressed buttons
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=10
  end

  -- illuminate currently pressed notes
  for k,_ in pairs(self.pressed_notes[self.voice_set]) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=10
  end
  -- finger pressed notes
  for i=voice_pair[1],voice_pair[2] do
    self.voices[i].current_note=""
    for _,k in ipairs(self:get_keys_sorted_by_value(self.voices[i].pressed)) do
      local row,col=k:match("(%d+),(%d+)")
      row=tonumber(row)
      col=tonumber(col)
      self.visual[row][col]=15
      local note=self:get_note_from_pos(i,row,col)
      self.voices[i].current_note=self.voices[i].current_note.." "..MusicUtil.note_num_to_name(note,true)
    end
  end



  return self.visual
end

function Plonky:record_add_rest_or_legato(voice)
  if params:get(voice.."record")==0 then
    do return end
  end
  local wtd="." -- rest
  if self.debug then
    print("cluster ",json.encode(self.voices[voice].cluster))
    print("record_steps ",json.encode(self.voices[voice].record_steps))
  end

  if next(self.voices[voice].cluster)~=nil then
    wtd="-"
    self.voices[voice].record_steps[self.voices[voice].record_step]=self.voices[voice].cluster
    self.voices[voice].cluster={}
  elseif next(self.voices[voice].record_steps)~=nil and self.voices[voice].record_steps[#self.voices[voice].record_steps][1]=="-" and next(self.voices[voice].pressed)~=nil and next(self.voices[voice].cluster)==nil then
    wtd="-"
  end
  self:record_update_step(voice)
  self.voices[voice].record_steps[self.voices[voice].record_step]={wtd}
end

function Plonky:record_update_step(voice)
  if self.debug then
    print("record_update_step",json.encode(self.voices[voice].record_steps))
  end
  self.voices[voice].record_step=self.voices[voice].record_step+1

  -- check adjustment
  if self.voices[voice].record_step_adj==0 then do return end end
-- erase steps
  -- local last=self.voices[voice].record_steps[#self.voices[voice].record_steps]
  for i=self.voices[voice].record_step_adj,0 do
    self.voices[voice].record_steps[self.voices[voice].record_step+i]=nil
  end
  if self.voices[voice].record_steps==nil then
    self.voices[voice].record_steps={}
  end
  self.voices[voice].record_step=self.voices[voice].record_step+self.voices[voice].record_step_adj-1
  -- self.voices[voice].record_steps[self.voices[voice].record_step]=last
  self.voices[voice].record_step=self.voices[voice].record_step+1
  self.voices[voice].record_step_adj=0
  if self.debug then
    print("record_update_step (adj)",json.encode(self.voices[voice].record_steps))
  end
end

function Plonky:key_press(row,col,on)
  if self.grid64 and not self.grid64default then
    col=col+8
  end

  local ct=self:current_time()
  local rc=row..","..col
  if on then
    self.pressed_buttons[rc]=ct
  else
    self.pressed_buttons[rc]=nil
  end


  -- determine voice
  local voice=1+self.voice_set
  if col>8 then
    voice=2+self.voice_set
  end

  if params:get("voice")~=voice and _menu.mode then
    params:set("voice",voice)
  end

  -- add to note cluster
  if on then
    self.voices[voice].pressed[rc]=ct
    if params:get(voice.."record")==1 and next(self.voices[voice].cluster)==nil then
      self:record_update_step(voice)
    end
    table.insert(self.voices[voice].cluster,rc)
  else
    self.voices[voice].pressed[rc]=nil
    local num_pressed=0
    for k,_ in pairs(self.voices[voice].pressed) do
      num_pressed=num_pressed+1
    end
    if num_pressed==0 then
      -- add the previous presses to note cluster
      if params:get(voice.."record")==1 then
        if next(self.voices[voice].cluster)~=nil then
          self.voices[voice].record_steps[self.voices[voice].record_step]=self.voices[voice].cluster
        end
        if self.debug then
          print(json.encode(self.voices[voice].record_steps))
        end
      else
        self.voices[voice].latched=self.voices[voice].cluster
        params:set(voice.."latch_steps",json.encode(self.voices[voice].cluster))
      end
      -- reset cluster
      self.voices[voice].cluster={}
    end
  end

  self:press_note(self.voice_set,row,col,on,true)
end

function Plonky:press_midi_note(name,channel,note,velocity,on)
  if self.debug then
    print("midi_note",name,channel,note,velocity,on)
  end
  -- WORK
  for i=1,self.num_voices do
    if i==self.voice_set+1 or i==self.voice_set+2 then
      if self.debug then
        print(i,name,self.device_list[params:get(i.."midi in")])
      end
      if name==self.device_list[params:get(i.."midi in")] and channel==params:get(i.."midichannelin") then
        local positions=self.voices[i].note_to_pos[note]
        if positions~=nil then
          self:key_press(positions[1][1],positions[1][2],on)
        end
      end
    end
  end
end

function Plonky:press_note(voice_set,row,col,on,is_finger)
  if on then
    self.pressed_notes[voice_set][row..","..col]=true
  else
    self.pressed_notes[voice_set][row..","..col]=nil
  end

  -- determine voice
  local voice=1+voice_set
  if col>8 then
    voice=2+voice_set
  end

  -- determine note
  local note=self:get_note_from_pos(voice,row,col)
  if self.debug then
    print("voice "..voice.." press note "..MusicUtil.note_num_to_name(note,true))
  end

  -- determine if muted
  if is_finger~=nil and is_finger then
    if params:get(voice.."arp")==1 and params:get(voice.."mute_non_arp")==1 then
      do return end
    end
  end

  -- play from engine
  if not self.engine_loaded then
    do return end
  end
  if params:get(voice.."engine_enabled")==2 then
    if string.sub(engine.name,1,2)=="Mx" then
      if on then
        self.mx:on({
          name=self.instrument_list[params:get(voice.."mx_instrument")],
          midi=note,
          velocity=velocity or params:get(voice.."mx_velocity"),
          amp=params:get(voice.."mx_amp"),
          attack=params:get(voice.."mx_attack"),
          release=params:get(voice.."mx_release"),
          pan=params:get(voice.."mx_pan"),
        })
      else
        self.mx:off({name=self.instrument_list[params:get(voice.."mx_instrument")],midi=note})
      end
    elseif engine.name=="PolyPerc" then
      if on then
        engine.amp(params:get(voice.."pp_amp"))
        engine.release(params:get(voice.."pp_release"))
        engine.cutoff(params:get(voice.."pp_cut"))
        engine.pw(params:get(voice.."pp_pw")/100)
        engine.hz(MusicUtil.note_num_to_freq(note))
      end
    elseif engine.name=="MollyThePoly" then
      if on then
        engine.oscWaveShape(params:get(voice.."osc_wave_shape")-1)
        engine.pwMod(params:get(voice.."pulse_width_mod"))
        engine.pwModSource(params:get(voice.."pulse_width_mod_src")-1)
        engine.freqModEnv(params:get(voice.."freq_mod_env"))
        engine.freqModLfo(params:get(voice.."freq_mod_lfo"))
        engine.glide(params:get(voice.."mtp_glide"))
        engine.mainOscLevel(params:get(voice.."main_osc_level"))
        engine.subOscLevel(params:get(voice.."sub_osc_level"))
        engine.subOscDetune(params:get(voice.."sub_osc_detune"))
        engine.noiseLevel(params:get(voice.."noise_level"))
        engine.hpFilterCutoff(params:get(voice.."hp_filter_cutoff"))
        engine.lpFilterCutoff(params:get(voice.."lp_filter_cutoff"))
        engine.lpFilterResonance(params:get(voice.."lp_filter_resonance"))
        engine.lpFilterType(params:get(voice.."lp_filter_type")-1)
        engine.lpFilterCutoffEnvSelect(params:get(voice.."lp_filter_env")-1)
        engine.lpFilterCutoffModEnv(params:get(voice.."lp_filter_mod_env"))
        engine.lpFilterCutoffModLfo(params:get(voice.."lp_filter_mod_lfo"))
        engine.lpFilterTracking(params:get(voice.."lp_filter_tracking"))
        engine.lfoFreq(params:get(voice.."lfo_freq"))
        engine.lfoFade(params:get(voice.."lfo_fade"))
        engine.lfoWaveShape(params:get(voice.."lfo_wave_shape")-1)
        engine.env1Attack(params:get(voice.."env_1_attack"))
        engine.env1Decay(params:get(voice.."env_1_decay"))
        engine.env1Sustain(params:get(voice.."env_1_sustain"))
        engine.env1Release(params:get(voice.."env_1_release"))
        engine.env2Attack(params:get(voice.."env_2_attack"))
        engine.env2Decay(params:get(voice.."env_2_decay"))
        engine.env2Sustain(params:get(voice.."env_2_sustain"))
        engine.env2Release(params:get(voice.."env_2_release"))
        engine.amp(params:get(voice.."mtp_amp"))
        engine.ampMod(params:get(voice.."mtp_amp_mod"))
        engine.ringModFreq(params:get(voice.."ring_mod_freq"))
        engine.ringModFade(params:get(voice.."ring_mod_fade"))
        engine.ringModMix(params:get(voice.."ring_mod_mix"))
        engine.chorusMix(params:get(voice.."chorus_mix"))
        engine.noteOn(note,MusicUtil.note_num_to_freq(note),80) --hardcoding velocity
      else
        engine.noteOff(note)
      end
    elseif engine.name=="Thebangs" then
      if on then
        engine.algoIndex(params:get(voice.."algo"))
        engine.stealMode(params:get(voice.."steal_mode")-1)
        engine.stealIndex(params:get(voice.."steal_index"))
        engine.maxVoices(params:get(voice.."max_voices"))
        engine.attack(params:get(voice.."b_attack"))
        engine.amp(params:get(voice.."b_amp"))
        engine.pw(params:get(voice.."b_pw")/100)
        engine.release(params:get(voice.."b_release"))
        engine.cutoff(params:get(voice.."b_cutoff"))
        engine.gain(params:get(voice.."b_gain"))
        engine.pan(params:get(voice.."b_pan"))
        engine.hz(MusicUtil.note_num_to_freq(note))
      end
    end
  end

  -- play on midi device
  if params:get(voice.."midi")>1 then
    if on then
      if self.debug then
        print(note.." -> "..self.device_list[params:get(voice.."midi")])
      end
      self.device[self.device_list[params:get(voice.."midi")]].midi:note_on(note,velocity or 80,params:get(voice.."midichannel"))
    else
      self.device[self.device_list[params:get(voice.."midi")]].midi:note_off(note,velocity or 80,params:get(voice.."midichannel"))
    end
  end

  -- play on crow
  if params:get(voice.."crow")>1 and on then
    if params:get(voice.."crow")==2 then
      crow.output[1].volts=(note-60)/12
      crow.output[2].execute()
    elseif params:get(voice.."crow")==3 then
      crow.output[3].volts=(note-60)/12
      crow.output[4].execute()
    elseif params:get(voice.."crow")==4 then
      crow.ii.jf.play_note((note-60)/12,5)
    end
  end
end

function Plonky:get_cluster(voice)
  s=""
  for _,rc in ipairs(self.voices[voice].cluster) do
    local row,col=rc:match("(%d+),(%d+)")
    row=tonumber(row)
    col=tonumber(col)
    local note_name=rc
    if col~=nil and row~=nil then
      local note=self:get_note_from_pos(voice,row,col)
      note_name=MusicUtil.note_num_to_name(note,true)
    end
    s=s..note_name.." "
  end
  return s
end

function Plonky:get_note_from_pos(voice,row,col)
  if voice%2==0 then
    col=col-8
  end
  return self.voices[voice].scale[(params:get(voice.."tuning")-1)*(col-1)+(9-row)]
end

function Plonky:get_keys_sorted_by_value(tbl)
  sortFunction=function(a,b) return a<b end

  local keys={}
  local keys_length=0
  for key in pairs(tbl) do
    keys_length=keys_length+1
    table.insert(keys,key)
  end

  table.sort(keys,function(a,b)
    return sortFunction(tbl[a],tbl[b])
  end)

  return keys,keys_length
end

function Plonky:get_keys_sorted_by_key(tbl)
  sortFunction=function(a,b) return a<b end

  local keys={}
  local keys_length=0
  for key in pairs(tbl) do
    keys_length=keys_length+1
    table.insert(keys,key)
  end

  table.sort(keys,function(a,b)
    return sortFunction(a,b)
  end)

  return keys,keys_length
end

function Plonky:current_time()
  return clock.get_beat_sec()*clock.get_beats()
end

function Plonky:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  if self.grid64 then
    e=8
    if not self.grid64default then
      s=9
      e=16
      adj=-8
    end
  end
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function Plonky:calculate_lfo(period_in_beats,offset)
  if period_in_beats==0 then
    return 1
  else
    return math.sin(2*math.pi*clock.get_beats()/period_in_beats+offset)
  end
end


return Plonky
