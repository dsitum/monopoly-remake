package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class dijalog_mc extends Sprite {
		private const PRIHVATI_GUMB:uint = 1;
		private const ODBIJ_GUMB:uint = 2;
		private static var _Prikazan:Boolean = false;  // označava stanje - je li dijalog prikazan na ekranu ili ne
		public static var Monopoly:Igra;
		
		public function dijalog_mc(tekst:String, sirina:uint=320, visina:uint=240, lokacijaX:uint=240, lokacijaY:uint=240) {
			this.Tekst.text = tekst;
			this.Prihvati.buttonMode = true;
			this.Odbij.buttonMode = true;
			this.Prihvati.gotoAndStop(PRIHVATI_GUMB);
			this.Odbij.gotoAndStop(ODBIJ_GUMB);
			this.Okvir.width = sirina;
			this.Okvir.height = visina;
			this.x = lokacijaX;
			this.y = lokacijaY;
			this.Prihvati.x = sirina / 2 - 45;
			this.Prihvati.y = visina / 2 - 40;
			this.Odbij.x = -0.5 * sirina + 44;
			this.Odbij.y = visina / 2 - 40;
			this.Tekst.y = -0.5 * visina + 15;
			this.addEventListener(Event.ADDED_TO_STAGE, DijalogJeStvoren);
			this.addEventListener(Event.REMOVED_FROM_STAGE, DijalogJeUklonjen);
		}
		
		public static function set Prikazan(prikazan:Boolean):void
		{
			// ovaj setter omogućava / onemogućava gumb za kraj poteza (ako se ne radi o AI-u)
			if (! igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
			{
				if (prikazan)	// ako tek prikazujemo dijalog
				{
					Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
					Monopoly.SakrijPokaziTradeGumb(false);
					Monopoly.KlikanjePoPlociOnOff(false);
				}
				else  // ako zatvaramo dijalog
				{
					if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac > 0 && Igra.KockeBacene)
						Monopoly.SakrijPokaziGumbZaKrajPoteza(true);
					Monopoly.SakrijPokaziTradeGumb(true);
					Monopoly.KlikanjePoPlociOnOff(true);
				}
			}
			
			_Prikazan = prikazan;
		}
		
		public static function get Prikazan():Boolean
		{
			return _Prikazan;
		}
		
		public function UkloniGumbX():void
		{
			this.Odbij.visible = false;
		}
		
		public function UkloniSavSadrzaj():void
		{
			this.Prihvati.visible = false;
			this.Odbij.visible = false;
			this.Tekst.visible = false;
		}
		
		// na ovaj dijalog moguće je dodati i novi objekt na zadanu lokaciju. Također je potrebno podesiti i frame objekta
		public function DodajNaDijalog(objekt:Sprite, frame:uint=1, pozicijaX:Number=160, pozicijaY:Number=120)
		{
			this.addChild(objekt);
			if (frame != 0)
				(objekt as MovieClip).gotoAndStop(frame);
			objekt.x = pozicijaX;
			objekt.y = pozicijaY;
		}
		
		private function DijalogJeStvoren(e:Event):void
		{
			// kada se instancira novi dijalog, postavljamo varijablu Prikazan na true (ima setter)
			this.removeEventListener(Event.ADDED_TO_STAGE, DijalogJeStvoren);
			Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
			Prikazan = true;  // postavljamo
		}
		
		private function DijalogJeUklonjen(e:Event):void
		{
			// kada se dijalog ukloni sa stage-a, postavljamo varijablu Prikazan na false (ima setter)
			this.removeEventListener(Event.REMOVED_FROM_STAGE, DijalogJeUklonjen);
			Monopoly.SakrijPokaziGumbZaKrajPoteza(true);
			Prikazan = false;
			Monopoly.KontejnerIgre.dispatchEvent(new Event("Dijalog zatvoren"));
		}
	}
}
