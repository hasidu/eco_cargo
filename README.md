# ECO CARGO 
Érdemes visszanézni, mert az első verzó óta javítások, bővítések történtek, melyek a továbbiakban is várhatók...
- 01.31: server/main.lua stat update bugfix
- 01.29: Rang rendszer bevezetve, statisztikát lehet javítani a különlegesen sérülékeny fuvar szállításával, pótkocsik cserélve, nehezen hozzáférhető pótkocsik áthelyezve. NUI felület átszinezve, statisztika átalakítva 

Kamionos munka - freight work for FiveM (ESX)
https://www.youtube.com/watch?v=Q2TpDI_MPdI

Konvoj videó:
https://youtu.be/8f7a2wVr2HU

![ecocargo gallery](https://github.com/Ekhion76/eco_cargo/blob/main/preview_images/eco_cargo_gallery.jpg)
[Képek](https://postimg.cc/gallery/hmm2bTb)

A GITHUB ÁTNEVEZI A LETÖLTÖTT SCRIPTET eco_cargo-main-ra! A '-main'-t TÖRÖLD KÜLÖNBEN NEM FOG MŰKÖDNI!!!
FONTOS: Ha több karakteres rendszert használsz:

Kashakter esetén, ellenőrizd, hogy a client/main.lua fájlban az alábbi eseménykezelő tartlamazza a esx:kashloaded triggert
Az eco_cargo config fájlban állitsd a Config.kashacters = true értékre.

RegisterNetEvent('kashactersC:SpawnCharacter')
AddEventHandler('kashactersC:SpawnCharacter', function(spawn, isnew)

    -- Betöltési folyamat...
    -- ...
    -- ...

    TriggerEvent('esx:kashloaded')
end)


## MISSZIÓK

    Az alábbi listákat a config.lua-ban állitsd be

    -- rendfentartók listája:
        Config.lawEnforcementFactions

    -- Illegális frakciók listája:
        Config.illegalFactions



## PARANCSOK

    ADMIN:
    -- /cargodiag   -- Adatbázis karbantartás

    PLAYER:
    -- /inspect     -- A trailer mellé állva lekéri a szállítólevelet
    -- /mission     -- Küldetéslista
    -- /cargostat   -- Játékosok fuvar statisztikája
    -- /closenui
    
## TEMPOMAT (beépítve: RP Friendly Cruise Control/Speed Limiter (https://github.com/hojgr/teb_speed_control))

    - Numpad '+' vagy görgő -- Sebesség növelés 10 Km/h -val
    - Numpad '-' vagy görgő -- Sebesség csökkentés 10 Km/h -val
    
A szkriptbe építve megtalálható a mythic_notify így azt külön telepíteni nem kell.
