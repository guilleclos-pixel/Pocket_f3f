-- Pocket_f3f 1.3 Rudder TEST10 - continuous body axes; experimental flight core
-- No RF functions, no model configuration changes.
local sin,cos,sqrt,abs,pi=math.sin,math.cos,math.sqrt,math.abs,math.pi
local function C(r,g,b) return lcd.RGB(r,g,b) end
local SKY=C(161,207,235);local SEA=C(50,134,168)
local LAND=C(99,111,81);local CLIFF=C(189,151,108);local SAND=C(222,194,142)
local TOP=C(255,211,36);local BOTTOM=C(45,54,69);local TIP=C(249,86,27)
local WHITE=C(241,242,239);local INK=C(22,49,72)
local function lim(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function stick(name)
 local v=getValue(name)
 if type(v)~='number' then return 0 end
 return lim(v/1024,-1,1)
end
-- Body basis stays continuous through vertical flight; Euler angles are display-only.
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function unit(a)
 local n=sqrt(dot(a,a));if n<0.0000001 then return {1,0,0} end
 return {a[1]/n,a[2]/n,a[3]/n}
end
local function cross(a,b)return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function pair(a,b,angle)
 local c,q=cos(angle),sin(angle)
 return {a[1]*c+b[1]*q,a[2]*c+b[2]*q,a[3]*c+b[3]*q},
        {b[1]*c-a[1]*q,b[2]*c-a[2]*q,b[3]*c-a[3]*q}
end
local function rotate(v,axis,angle)
 local c,q=cos(angle),sin(angle);local d=dot(v,axis);local k=cross(axis,v)
 return {v[1]*c+k[1]*q+axis[1]*d*(1-c),v[2]*c+k[2]*q+axis[2]*d*(1-c),v[3]*c+k[3]*q+axis[3]*d*(1-c)}
end
-- Experimental ridge wind: air-relative velocity is V; ground motion adds wind.
local RIDGE_UP=8.0 -- m/s peak, deliberately tunable; not calibrated to a real site
local function create(zone,options)
 return {zone=zone,last=getTime(),timer=getTime(),frames=0,fps=0,
 x=0,y=-18,z=33,heading=pi/2,bank=0,pitch=0,F={1,0,0},W={0,1,0},U={0,0,1},V={34,0,0},yawRate=0,lastTurn=0,pitchFall=false,vertical=false,velocity=34, lift=0,crashed=false,resetHeld=false,
 launch=0, prepStart=getTime(),runStart=nil,runEnd=nil,entered=false,legs=0,nextBase=nil,baseLast=0,finishTone=false,lastCount=31,penalties=0,penLast=0,rearActive=false,lastSignal=0,lastWhistle=-600,pendingBaseTone=0,pendingBaseAt=0,voiceLaunch=false,voiceThirty=false,pendingRaceVoice=nil,pendingRaceVoiceAt=0}
end
local function triangle(a,b,c,col)
 lcd.drawFilledTriangle(math.floor(a[1]),math.floor(a[2]),math.floor(b[1]),math.floor(b[2]),math.floor(c[1]),math.floor(c[2]),col)
end
local function refresh(s,event,touch)
 local t=getTime(); local dt=lim((t-s.last)/100,0,0.14);s.last=t
 local rawA=stick('ail');local rawE=stick('ele')
 local rud=stick('rud')
 rud=abs(rud)<=0.025 and 0 or (rud>0 and 1 or -1)*(abs(rud)-0.025)/0.975
 -- Invert directions requested from radio test; leave real radio model unchanged.
 local ail=-rawA;local ele=-rawE
 -- SH momentary switch: reset on positive transition, if present.
 local sh=getValue('sh')
 local held=type(sh)=='number' and sh>500
 if held and not s.resetHeld then
  s.x=0;s.y=-18;s.z=33;s.heading=pi/2;s.bank=0;s.pitch=0
  s.F={1,0,0};s.W={0,1,0};s.U={0,0,1};s.V={34,0,0};s.yawRate=0;s.lastTurn=0;s.pitchFall=false;s.vertical=false
  s.velocity=34;s.lift=0;s.crashed=false;s.last=t;dt=0
  s.prepStart=t;s.runStart=nil;s.runEnd=nil;s.entered=false;s.legs=0;s.nextBase=nil;s.baseLast=t;s.lastCount=31;s.penalties=0;s.penLast=0;s.rearActive=false;s.lastSignal=t;s.lastWhistle=t-600;s.pendingBaseTone=0;s.pendingBaseAt=0;s.voiceLaunch=false;s.voiceThirty=false;s.pendingRaceVoice=nil;s.pendingRaceVoiceAt=0
 end
 s.resetHeld=held
 -- Experimental voice announcements: separate WAVs in the existing Spanish sound directory.
 -- 30-second prompt is delayed so it does not overlap the launch announcement.
 -- Once the run has started, pending preparation announcements are suppressed.
 if not s.voiceLaunch and not s.crashed and type(playFile)=='function' then
  playFile('/SOUNDS/es/launch1.wav')
  s.voiceLaunch=true
 end
 if not s.voiceThirty and not s.entered and not s.runEnd and not s.crashed
     and t-s.prepStart>=145 and t-s.prepStart<900 and type(playFile)=='function' then
  playFile('/SOUNDS/es/thirty.wav')
  s.voiceThirty=true
 end
 -- Acoustic preparation: one event per countdown second transition.
 -- Low sound at 10/5, short high ticks at 4,3,2,1; distinct READY at zero.
 if not s.entered and not s.runEnd and not s.crashed then
  local remaining=math.max(0,30-math.floor((t-s.prepStart)/100))
  if remaining<s.lastCount then
   if type(playTone)=='function' then
    if remaining==10 then
      if type(playFile)=='function' then playFile('/SOUNDS/es/ten.wav')
      else playTone(740,130,0,0) end
    elseif remaining>=1 and remaining<=5 then
      local word=({[5]='five',[4]='four',[3]='three',[2]='two',[1]='one'})[remaining]
      if type(playFile)=='function' then playFile('/SOUNDS/es/'..word..'.wav')
      else playTone(1000,90,0,0) end
    elseif remaining==0 then playTone(1400,250,0,0) end
   end
   s.lastCount=remaining
  end
 end
 -- Continuous body controls with experimental energy/inertia integration.
 -- Crash freezes the aircraft until SH is pressed again.
 if not s.crashed then
  local speedExcess=lim((s.velocity-34)/41,0,1)
  local rollFeel=ail==0 and 0 or (ail>0 and 1 or -1)*abs(ail)^0.62
  local elevatorFeel=ele==0 and 0 or (ele>0 and 1 or -1)*abs(ele)^0.61
  local outer=lim((abs(ele)-0.48)/0.52,0,1)
  local lowSpeedControl=lim((s.velocity/22)^2,0.12,1)
  local elevatorRate=lowSpeedControl*1.54*elevatorFeel*(1+0.35*speedExcess)*(1+0.40*outer*outer*(3-2*outer))
  -- All three commands use CURRENT BODY axes, never a reconstituted bank sign.
  s.W,s.U=pair(s.W,s.U,rollFeel*dt*2.76*(1+0.38*speedExcess))
  local pitchAxis=s.W
  s.F,s.U=pair(s.F,s.U,elevatorRate*dt)
  if not s.vertical then s.V=rotate(s.V,pitchAxis,-elevatorRate*dt) end
  if not s.vertical and ((s.F[3]>0.819152 and s.V[3]>0 and abs(ele)<0.12) or s.velocity<12) then s.vertical=true end
  local rudAuthority=lim((s.velocity/34)^2,0.45,1.25)
  local yawLimit=s.vertical and 1.60 or 1.0
  local yawTarget=rud*(s.vertical and 1.30 or 0.80)*math.max(rudAuthority,s.vertical and 0.85 or 0)
  if abs(rud)>0.03 then s.lastTurn=rud>0 and 1 or -1 end
  if s.vertical and s.V[3]< -0.5 then
   -- Continuous two-axis weathercock recovery towards the descending airflow.
   -- A yaw-only controller cannot recover all bank/pitch combinations.
   local alignment=lim(s.velocity/10,0.65,2.8)
   local yawRecovery=-s.W[3]*alignment
   local pitchRecovery=-s.U[3]*alignment
   if s.F[3]>0.98 and abs(yawRecovery)+abs(pitchRecovery)<0.15 then
    -- Break the exactly nose-up symmetry without reversing the selected side.
    if s.lastTurn~=0 then yawRecovery=s.lastTurn*0.8 else pitchRecovery=-0.8 end
   end
   yawTarget=yawTarget+yawRecovery*(1-abs(rud))^2
   local pitchStep=lim(pitchRecovery,-1.8,1.8)*(1-abs(ele))^2*dt
   s.F,s.U=pair(s.F,s.U,pitchStep)
  elseif not s.vertical then
   local error=math.atan2(dot(s.V,s.W),dot(s.V,s.F))
   yawTarget=yawTarget+error*0.85*(1-abs(rud))^2
  end
  s.yawRate=lim(s.yawRate+(lim(yawTarget,-yawLimit,yawLimit)-s.yawRate)*(1-math.exp(-dt/0.18)),-yawLimit,yawLimit)
  s.F,s.W=pair(s.F,s.W,s.yawRate*dt)
  -- Numerical orthonormalisation: no attitude switches at the vertical pole.
  s.F=unit(s.F);s.U=unit(cross(s.F,s.W));s.W=unit(cross(s.U,s.F))
  s.pitch=math.atan2(s.F[3],sqrt(s.F[1]^2+s.F[2]^2))
  s.heading=math.atan2(s.F[1],-s.F[2]);s.bank=math.atan2(s.W[3],s.U[3])
  local shore=abs(s.y+12);local updraft=0
  if s.y<=20 and s.y>=-105 then updraft=RIDGE_UP*lim(1-shore/55,0,1)*lim(1-(s.z-20)/150,0,1) end
  s.lift=updraft
  local oldX=s.x;local oldY=s.y;local nx,ny,nz
  if s.vertical then
   local previousVz=s.V[3]
   local speed=sqrt(dot(s.V,s.V))
   local drag=.10+.00018*speed*speed
   local damping=speed>0.001 and math.max(0,1-drag*dt/speed) or 1
   s.V[1]=s.V[1]*damping;s.V[2]=s.V[2]*damping
   s.V[3]=s.V[3]*damping-9.81*dt
   nx=s.x+s.V[1]*dt;ny=s.y+s.V[2]*dt;nz=s.z+((previousVz+s.V[3])*0.5+updraft-.65)*dt
   -- Do not lock elevator control out until a yaw-rate threshold is satisfied.
   local pilotRecovery=abs(ele)>0.12 and s.velocity>15 and s.V[3]<0
   local naturalRecovery=abs(rud)<0.03 and s.F[3]< -0.80 and s.V[3]< -8
   if pilotRecovery or naturalRecovery then s.vertical=false;s.pitchFall=false end
  else
   -- Speed follows the ACTUAL trajectory slope, not where the nose points.
   -- Midpoint displacement converts gravity's work into kinetic energy.
   local direction=unit(s.V);local blend=1-math.exp(-dt/1.6)
   direction=unit({direction[1]+(s.F[1]-direction[1])*blend,direction[2]+(s.F[2]-direction[2])*blend,direction[3]+(s.F[3]-direction[3])*blend})
   local oldSpeed=sqrt(dot(s.V,s.V))
   local drag=.10+.00018*oldSpeed*oldSpeed
   local v=math.max(0,oldSpeed+(-9.81*direction[3]-drag)*dt)
   local travelSpeed=(oldSpeed+v)*0.5
   s.V={direction[1]*v,direction[2]*v,direction[3]*v}
   nx=s.x+direction[1]*travelSpeed*dt
   ny=s.y+direction[2]*travelSpeed*dt
   nz=s.z+(direction[3]*travelSpeed+updraft-.65)*dt
  end
  s.velocity=sqrt(dot(s.V,s.V))
  -- Ground follows the rendered slope: plateau z=20, cliff z=0..20,
  -- beach/sea z=0. Collision uses current AND proposed position.
  local function terrainY(yy)
   if yy>=0 then return 20 end
   if yy>=-33 then return 20*(yy+33)/33 end
   return 0
  end
  local surface=math.max(terrainY(s.y),terrainY(ny))
  if nz<=surface+1.0 then
   s.x=nx;s.y=ny;s.z=surface+1.0;s.crashed=true
   if type(playTone)=='function' then playTone(280,400,0,PLAY_NOW or 0) end
  else
   s.x=nx;s.y=ny;s.z=nz
   -- F3F: A is x=-50, B is x=+50, separated by 100 m.
   -- Legal entry is crossing A INTO the course towards B (increasing x).
   -- Countdown begins on reset / launch (simplified simulator).
   -- At 30 seconds the official flight timer starts automatically,
   -- even if the model has NOT entered the course. Late time is included.
   if not s.runStart and t-s.prepStart>=3000 then
    s.runStart=s.prepStart+3000
    if type(playTone)=='function' then playTone(610,450,0,PLAY_NOW or 0) end
   end
   local crossAin=(oldX< -50 and nx>= -50)
   local crossAout=(oldX> -50 and nx<= -50)
   local crossBout=(oldX<50 and nx>=50)
   local crossBin=(oldX>50 and nx<=50)
   -- Safety plane is parallel to the course (rear, landward of ridge).
   -- Detect entry into rear airspace separately from base crossings.
   -- Register ONE penalty per excursion, not one per base or frame.
   -- Plane set 1.5 m landward of the ridge edge (y=0).
   local rearNow=(ny>1.5)
   if s.entered and not s.runEnd and rearNow and not s.rearActive then
    s.penalties=s.penalties+1;s.penLast=t
    s.lastSignal=t
    if type(playTone)=='function' then playTone(330,650,0,PLAY_NOW or 0) end
   end
   s.rearActive=rearNow
   -- Base crossings must still count and beep when behind the safety plane.
   -- Correct outward directions: B x>50, A x<-50.
   if not s.runEnd and t-s.baseLast>=35 then
    if not s.entered then
     -- Preparation phase: crossing A outwards (towards left) must beep,
     -- but it MUST NOT start the competition clock or count as a leg.
     if crossAout then
      s.baseLast=t
      s.lastSignal=t
      if type(playTone)=='function' then playTone(1040,115,0,PLAY_NOW or 0) end
     elseif crossAin then
      if not s.runStart then s.runStart=t end
      s.entered=true;s.nextBase=1;s.legs=0;s.baseLast=t
      s.lastSignal=t
      if type(playTone)=='function' then
       if t-s.penLast<85 and s.penLast>0 then s.pendingBaseTone=950;s.pendingBaseAt=t+85
       else playTone(950,170,0,PLAY_NOW or 0) end
      end
     end
    elseif (s.nextBase==1 and crossBout) or (s.nextBase==-1 and crossAout) then
     s.legs=s.legs+1
     s.nextBase=-s.nextBase
     s.baseLast=t
     s.lastSignal=t
     if type(playTone)=='function' then
      local freq=(s.legs>=10) and 1350 or 1150
      if t-s.penLast<85 and s.penLast>0 then s.pendingBaseTone=freq;s.pendingBaseAt=t+85
      else playTone(freq,(s.legs>=10) and 350 or 85,0,PLAY_NOW or 0) end
     end
     if s.legs==9 and type(playFile)=='function' then
      -- A base signal is vital; queue speech until it has sounded.
      s.pendingRaceVoice='lastleg';s.pendingRaceVoiceAt=t+55
     end
     if s.legs>=10 then
      s.runEnd=t
      if type(playFile)=='function' then
       s.pendingRaceVoice='finish';s.pendingRaceVoiceAt=t+55
      end
     end
    end
   end
   -- Original single flyby sample: only when crossing directly in front of the pilot.
   -- No repeated sound loops, so competition tones are not continuously masked.
   -- Pass direction may be either left-to-right or right-to-left.
   -- Start the flyby ~22 m before crossing the pilot, in either direction.
   -- Single-peak sample with smooth attack and release; no repetition inside the WAV.
   local approachingCenter=(oldX< -22 and nx>= -22) or (oldX>22 and nx<=22)
   local pilotDistance=sqrt(nx*nx+(ny-.8)*(ny-.8)+(nz-24)*(nz-24))
   if approachingCenter and pilotDistance<85 and s.velocity>=28
       and t-s.lastWhistle>=280 and t-s.lastSignal>=75
       and s.pendingBaseTone==0 and type(playFile)=='function' then
    playFile('/SOUNDS/es/pf3fpass.wav')
    s.lastWhistle=t
   end
  end
  -- No automatic teleport at x=+/-220 m (or elsewhere).
  -- Flying beyond base A/B for launch setup is permitted; SH resets explicitly.
 end
 if s.pendingBaseTone>0 and t>=s.pendingBaseAt and type(playTone)=='function' then
  playTone(s.pendingBaseTone,(s.pendingBaseTone==1350) and 350 or 110,0,PLAY_NOW or 0)
  s.pendingBaseTone=0;s.lastSignal=t
 end
 -- Delayed end-of-race announcements: keep the base beep first.
 -- Do not displace a base tone waiting for a penalty sound to finish.
 if s.pendingRaceVoice and t>=s.pendingRaceVoiceAt
     and s.pendingBaseTone==0 and t-s.lastSignal>=45 then
  if type(playFile)=='function' then
   playFile('/SOUNDS/es/'..s.pendingRaceVoice..'.wav')
  end
  s.pendingRaceVoice=nil
 end
 local r=s.zone or {};local x=r.x or 0;local y=r.y or 0
 local w=r.w or LCD_W;local h=r.h or LCD_H
 if w<90 or h<70 then return end
 -- World locked camera: pilot never moves, only looks towards the aircraft.
 local ex=s.x;local ey=s.y-0.8;local ez=s.z-24
 local dist=sqrt(ex*ex+ey*ey+ez*ez)
 local az=math.atan2(ex,-ey);local elev=math.atan2(ez,sqrt(ex*ex+ey*ey))
 local ca=cos(az);local sa=sin(az);local ce=cos(elev);local se=sin(elev)
 local focal=math.min(w*1.05,h*1.10)
 local cx=x+w*.5;local cy=y+h*.52
 local function proj(px,py,pz)
  local dx=px;local dy=py-0.8;local dz=pz-24
  local f=-dy*ca+dx*sa
  local right=dx*ca+dy*sa
  local up=dz*ce-f*se
  local depth=f*ce+dz*se
  if depth<2 then return nil end
  return {cx+right*focal/depth,cy-up*focal/depth,depth}
 end
 -- Cheap horizon responds to camera pitch; no large polygons behind camera.
 lcd.drawFilledRectangle(x,y,w,h,SKY)
 local horizon=lim(math.floor(cy+focal*math.tan(elev)),y,y+h)
 if horizon<y+h then lcd.drawFilledRectangle(x,horizon,w,y+h-horizon,SEA) end
 -- Four terrain planes in real world coordinates, with near-plane clipping.
 -- The pilot is at (0,0.8,24); the ridge edge is y=0 at z=20.
 -- A triangle with a vertex behind the camera must be clipped, NOT discarded.
 local function cameraPoint(px,py,pz)
  local dx=px; local dy=py-0.8; local dz=pz-24
  local f=-dy*ca+dx*sa
  local right=dx*ca+dy*sa
  local up=dz*ce-f*se
  return {right,up,f*ce+dz*se}
 end
 local function clipPoly(poly)
  local out={};local near=2
  for i=1,#poly do
   local a=poly[i]; local b=poly[i % #poly+1]
   local ia=a[3]>=near;local ib=b[3]>=near
   if ia then out[#out+1]=a end
   if ia~=ib then
    local t2=(near-a[3])/(b[3]-a[3])
    out[#out+1]={a[1]+(b[1]-a[1])*t2,a[2]+(b[2]-a[2])*t2,near}
   end
  end
  return out
 end
 local function groundQuad(yNear,zNear,yFar,zFar,col)
  local corners={cameraPoint(-280,yNear,zNear),cameraPoint(280,yNear,zNear),
    cameraPoint(280,yFar,zFar),cameraPoint(-280,yFar,zFar)}
  local clipped=clipPoly(corners)
  if #clipped<3 then return end
  -- Restrict extreme projected vertices to a region around the LCD.
  -- EdgeTX no longer receives triangles with 12000-pixel coordinates.
  local xmin=x-w; local xmax=x+2*w
  local ymin=y-h; local ymax=y+2*h
  local pts={}
  -- Project once and reject polygons outside the visible widget.
  -- Never call EdgeTX filled-triangle for a fully offscreen triangle.
  local lowX,highX,lowY,highY=100000,-100000,100000,-100000
  for i=1,#clipped do
   local q=clipped[i]
   local px=lim(math.floor(cx+q[1]*focal/q[3]),xmin,xmax)
   local py=lim(math.floor(cy-q[2]*focal/q[3]),ymin,ymax)
   pts[i]={px,py}
   if px<lowX then lowX=px end
   if px>highX then highX=px end
   if py<lowY then lowY=py end
   if py>highY then highY=py end
  end
  if highX<x or lowX>x+w or highY<y or lowY>y+h then return end
  local p0=pts[1]
  for i=2,#pts-1 do
   local p1=pts[i];local p2=pts[i+1]
   if not ((p0[1]<x and p1[1]<x and p2[1]<x)
        or (p0[1]>x+w and p1[1]>x+w and p2[1]>x+w)
        or (p0[2]<y and p1[2]<y and p2[2]<y)
        or (p0[2]>y+h and p1[2]>y+h and p2[2]>y+h)) then
    triangle(p0,p1,p2,col)
   end
  end
 end
 -- Sea is drawn by the horizon background; overlay a sandy shoreline,
 -- a sloping cliff and the flat land on top of it.
 groundQuad(-67,0,-33,0,SAND)
 groundQuad(-33,0,0,20,CLIFF)
 groundQuad(0,20,350,20,LAND)
 -- A visible world-anchored ridge line and a few depth cues.
 local function lineWorld(xa,ya,za,xb,yb,zb,col)
  local a=cameraPoint(xa,ya,za);local b=cameraPoint(xb,yb,zb)
  if a[3]<2 and b[3]<2 then return end
  if a[3]<2 or b[3]<2 then
   local t2=(2-a[3])/(b[3]-a[3])
   local q={a[1]+(b[1]-a[1])*t2,a[2]+(b[2]-a[2])*t2,2}
   if a[3]<2 then a=q else b=q end
  end
  lcd.drawLine(lim(math.floor(cx+a[1]*focal/a[3]),x-w,x+2*w),
    lim(math.floor(cy-a[2]*focal/a[3]),y-h,y+2*h),
    lim(math.floor(cx+b[1]*focal/b[3]),x-w,x+2*w),
    lim(math.floor(cy-b[2]*focal/b[3]),y-h,y+2*h),SOLID,col)
 end
 lineWorld(-280,0,20,280,0,20,WHITE)
 -- Extra guide lines omitted to reduce LCD draw calls.
 -- Bases anchored in world coordinates. Draw them only when in front.
 for _,bx in ipairs({-50,50}) do
  local foot=proj(bx,1,20);local head=proj(bx,1,34)
  if foot and head then
   local xx=math.floor(foot[1]);local y0=math.floor(foot[2]);local yy=math.floor(head[2])
   lcd.drawLine(xx,yy,xx,y0,SOLID,WHITE)
   lcd.drawLine(xx+1,yy,xx+1,y0,SOLID,WHITE)
   local ya=math.floor(yy+(y0-yy)*.28);local yb=math.floor(yy+(y0-yy)*.54)
   lcd.drawLine(xx,ya,xx,yb,SOLID,TIP)
   lcd.drawLine(xx+1,ya,xx+1,yb,SOLID,TIP)
  end
 end
 -- Glider local axes. Model dimensions: 3.8m span, 1.75m length.
 local forward=s.F;local wing=s.W;local up=s.U
 local function vp(f,v,u)
  return {s.x+forward[1]*f+wing[1]*v+up[1]*u,
          s.y+forward[2]*f+wing[2]*v+up[2]*u,
          s.z+forward[3]*f+wing[3]*v+up[3]*u}
 end
 local function pp(f,v,u)
  local q=vp(f*3.5,v*3.5,u*3.5);return proj(q[1],q[2],q[3])
 end
 -- Magnification applies ONLY to visual model dimensions.
 -- True perspective continues to reduce image size with distance.
 local visualScale=3.5
 local nose=pp(1.0,0,0);local tail=pp(-.85,0,0)
 local lw=pp(0,-1.9,0);local rw=pp(0,1.9,0)
 local root1=pp(.10,0,0);local root2=pp(-.23,0,0)
 if lw and rw and root1 and root2 then
  local normal={up[1],up[2],up[3]}
  local toEye={-ex,-ey,-ez}
  local side=normal[1]*toEye[1]+normal[2]*toEye[2]+normal[3]*toEye[3]
  local col=side>=0 and TOP or BOTTOM
  triangle(lw,rw,root1,col);triangle(lw,rw,root2,col)
  local tipL=pp(0,-1.65,0);local tipR=pp(0,1.65,0)
  if tipL then lcd.drawLine(math.floor(lw[1]),math.floor(lw[2]),math.floor(tipL[1]),math.floor(tipL[2]),SOLID,TIP) end
  if tipR then lcd.drawLine(math.floor(rw[1]),math.floor(rw[2]),math.floor(tipR[1]),math.floor(tipR[2]),SOLID,TIP) end
 end
 if nose and tail then
  lcd.drawLine(math.floor(nose[1]),math.floor(nose[2]),math.floor(tail[1]),math.floor(tail[2]),SOLID,INK)
 end
 -- T-tail: vertical fin attached to fuselage and elevated horizontal stabilizer.
 -- All points use the SAME local 3D axes and camera as the wing.
 local finBase=pp(-.76,0,.02)
 local finTop=pp(-.78,0,.49)
 local finFront=pp(-.59,0,.04)
 if finBase and finTop and finFront then
  triangle(finBase,finTop,finFront,INK)
  lcd.drawLine(math.floor(finBase[1]),math.floor(finBase[2]),math.floor(finTop[1]),math.floor(finTop[2]),SOLID,WHITE)
 end
 local tl=pp(-.78,-.34,.49)
 local tr=pp(-.78,.34,.49)
 local tc=pp(-.68,0,.49)
 local te=pp(-.90,0,.49)
 if tl and tr and tc and te then
  triangle(tl,tr,tc,WHITE)
  triangle(tl,tr,te,WHITE)
  lcd.drawLine(math.floor(tl[1]),math.floor(tl[2]),math.floor(tr[1]),math.floor(tr[2]),SOLID,INK)
 end
 s.frames=s.frames+1
 if t-s.timer>=100 then
  s.fps=math.floor(s.frames*100/(t-s.timer)+.5);s.timer=t;s.frames=0
 end
 lcd.drawText(x+6,y+3,'F3F 1.3 RUD TEST10',SMLSIZE+INK)
 lcd.drawText(x+6,y+20,'FPS '..s.fps..' A '..math.floor(ail*100)..' E '..math.floor(ele*100)..' R '..math.floor(rud*100)..(s.vertical and ' VERT' or ''),SMLSIZE+INK)
 local f3fText
 if s.runEnd then
  f3fText=string.format('META 10/10  %.2fs',(s.runEnd-s.runStart)/100)
 elseif s.entered then
  f3fText=string.format('F3F %d/10  %.2fs  SIG %s',s.legs,(t-s.runStart)/100,s.nextBase==-1 and 'A' or 'B')
 elseif s.runStart then
  f3fText=string.format('TIEMPO +%.1fs  ENTRA A>B',(t-s.runStart)/100)
 else
  local remain=math.max(0,30-(t-s.prepStart)/100)
  if remain>0 then f3fText=string.format('PREP %.0fs',math.ceil(remain))
  else f3fText='ENTRA POR A HACIA B' end
 end
 lcd.drawText(x+6,y+35,f3fText,SMLSIZE+INK)
 if s.penalties>0 then lcd.drawText(x+6,y+50,'AVISOS TRASEROS '..s.penalties,SMLSIZE+INK) end
 lcd.drawText(x+6,y+h-21,'V '..math.floor(s.velocity*3.6+.5)..'km/h H '..math.floor(s.z)..'m L '..string.format('%.1f',s.lift)..' SH',SMLSIZE+INK)
 if s.crashed then
  lcd.drawFilledRectangle(x+math.floor(w*.25),y+math.floor(h*.43),math.floor(w*.50),36,INK)
  lcd.drawText(x+math.floor(w*.28),y+math.floor(h*.45),'IMPACTO - SH REINICIA',SMLSIZE+WHITE)
 end
end
return {name='F3FRUD10',options={},create=create,refresh=refresh}
