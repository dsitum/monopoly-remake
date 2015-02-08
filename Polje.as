package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class Polje extends Sprite {
		protected const DOLJE:uint = 0, LIJEVO:uint = 1, GORE:uint = 2, DESNO:uint = 3;  // predstavlja stranu ploče na kojoj se može nalaziti neko polje
		public static const SMEDJE_POLJE:uint = 0;
		public static const SVIJETLO_PLAVO_POLJE:uint = 1;
		public static const ROZNO_POLJE:uint = 2;
		public static const NARANCASTO_POLJE:uint = 3;
		public static const CRVENO_POLJE:uint = 4;
		public static const ZUTO_POLJE:uint = 5;
		public static const ZELENO_POLJE:uint = 6;
		public static const TAMNO_PLAVO_POLJE:uint = 7;
		public static const ZELJEZNICKA_STANICA_POLJE:uint = 8;
		public static const KOMUNALIJE_POLJE:uint = 9;
		public static const DRZAVNA_BLAGAJNA_POLJE:uint = 10;
		public static const SANSA_POLJE:uint = 11;
		public static const POREZ_POLJE:uint = 12;
		public static const KRENI_POLJE:uint = 13;
		public static const SLOBODNO_POLJE:uint = 14;
		public static const IDITE_U_ZATVOR_POLJE:uint = 15;		
		
		private static const POREZ_NA_DOBIT:uint = 4;  // indeks na ploči na kojem se nalazi polje "Porez na dobit"
		public static var Polja:Vector.<Polje> = new Vector.<Polje>();
		public static var Monopoly:Igra;
		protected var IndeksPolja:uint;	// poprima vrijednost 0-40. Označava INDEKS POLJA na ploči na kojem se igrač zaustavio
		public var VrstaPolja:uint;	// poprima vrijednost jedne od gore navedenih konstanti
		public var NazivPolja:String;	// svako polje ima naziv (npr. Ilica, Šansa ...)
		public var Koordinate:Point;	// koordinate gornje desne točke polja. Kod zemljišta, gornja desna točka je ona ispod boje (i ispod crne crte)
		
		
		public function Polje(nazivPolja:String, indeksPolja:uint, koordinate:Point, vrstaPolja:uint) {
			IndeksPolja = indeksPolja;
			VrstaPolja = vrstaPolja;
			NazivPolja = nazivPolja;
			Koordinate = koordinate;
		}
		
		// kada neki igrač baci kockice i zaustavi se na nekom polju, pozvat će se ova funkcija
		public function IgracStaoNaPolje():void
		{
			var igracNaPotezu:igrac_mc = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
			var indeksPoljaNaPlociGdjeJeStao:uint = igracNaPotezu.Figurica.Pozicija;
			
			switch (VrstaPolja)
			{
				case KRENI_POLJE:
				case SLOBODNO_POLJE:  // ove 2 vrste polja nemaju nikakvu posebnu akciju
					break;
				case IDITE_U_ZATVOR_POLJE:
					igracNaPotezu.UZatvoru = new Zatvor();  // čim se instancira objekt tipa zatvor, pomiče igrača u zatvor
					igracNaPotezu.UZatvoru.addEventListener("Izadji iz zatvora" + igrac_mc.IgracNaPotezu, igracNaPotezu.IzadjiIzZatvora);
					igracNaPotezu.addChild(igracNaPotezu.UZatvoru);
					break;
				case POREZ_POLJE:  // ako je igrač stao na polje s porezom, sve što moramo učiniti je uzeti mu novac
					igracNaPotezu.ZadnjePlacanje = -1;
					if (indeksPoljaNaPlociGdjeJeStao == POREZ_NA_DOBIT)
						igracNaPotezu.Novac -= 4000;
					else  // ako se ne radi o porezu na dobit, onda se radi o "Super porezu"
						igracNaPotezu.Novac -= 2000;
					break;
				case SMEDJE_POLJE:
				case SVIJETLO_PLAVO_POLJE:
				case ROZNO_POLJE:
				case NARANCASTO_POLJE:
				case CRVENO_POLJE:
				case ZUTO_POLJE:
				case ZELENO_POLJE:
				case TAMNO_PLAVO_POLJE:
					var indeksUPoljuZemljista:uint = Zemljiste.PronadjiIndeksUPoljuZemljista(indeksPoljaNaPlociGdjeJeStao);
					// pozivamo metodu koja će dati reakciju na to što je igrač stao na zemljište (dijalog za kupovinu, plaćanje najamnine itd)
					Zemljiste.Zemljista[indeksUPoljuZemljista].IgracStaoNaZemljiste();
					break;
				case ZELJEZNICKA_STANICA_POLJE:
					var indeksUPoljuZeljeznickihStanica:uint = ZeljeznickaStanica.PronadjiIndeksUPoljuZeljznickihStanica(indeksPoljaNaPlociGdjeJeStao);
					ZeljeznickaStanica.ZeljeznickeStanice[indeksUPoljuZeljeznickihStanica].IgracStaoNaZeljeznickuStanicu();
					break;
				case KOMUNALIJE_POLJE:
					var indeksUPoljuKomunalnihUstanova:uint = KomunalnaUstanova.PronadjiIndeksUPoljuZeljznickihStanica(indeksPoljaNaPlociGdjeJeStao);
					KomunalnaUstanova.KomunalneUstanove[indeksUPoljuKomunalnihUstanova].IgracStaoNaKomunalnuUstanovu();
					break;
				case SANSA_POLJE:
					Monopoly.PoljaSrece.OtvoriKarticuSrece(SANSA_POLJE); break;
				case DRZAVNA_BLAGAJNA_POLJE:
					Monopoly.PoljaSrece.OtvoriKarticuSrece(DRZAVNA_BLAGAJNA_POLJE); break;
			}
			
			// okidamo event koji ima naziv polja na kojeg je igrač stao (tipa "Ilica", "Šansa", itd)
			igracNaPotezu.dispatchEvent(new Event(NazivPolja, true));
			// ako igrač nije u zatvoru ili nije na mjestu šanse ili državne blagajne...
			if (igracNaPotezu.UZatvoru == null && VrstaPolja != SANSA_POLJE && VrstaPolja != DRZAVNA_BLAGAJNA_POLJE)
			{
				if (Polja[indeksPoljaNaPlociGdjeJeStao] is Posjed)  // ako je igrač stao na posjed ...
				{
					var posjed:Posjed = Polja[indeksPoljaNaPlociGdjeJeStao] as Posjed;
					if (posjed.Vlasnik != -1)  // ... i taj posjed je kupljen, samo ćemo u tom slučaju završiti bacanje / omogućiti igraču gumb za završetak poteza.
						ZavrsiBacanje();
					else  // U suprotnom ćemo pričekati da se posjed kupi (ili direktno ili na aukciji)
						posjed.addEventListener("Posjed kupljen", ZavrsiBacanje);
				} 
				else  // a ako igrač nije stao na posjed, jednostavno ćemo završiti bacanje / dodati gumb za završavanje bacanja
				{
					ZavrsiBacanje();
				}
			}
		}
		
		public function VratiSredinuPolja():Point
		{
			const DEBLJINA_CRNE_CRTE:Number = 1.1;  // 1.11px
			// postavljamo sredinu traženog polja na početnu poziciju tog polja
			var sredina:Point = new Point(Koordinate.x, Koordinate.y);
			var stranaPloce = Math.floor(this.IndeksPolja / 10);  // strana ploče na kojoj se nalazi polje
			var koordianteSljedecegPolja:Point = Polja[(this.IndeksPolja + 1) % 40].Koordinate;
			
			// korigiramo jednu od koordinata kako bi točka odgovarala sredini polja (npr., ako se polje nalazi dolje, korigirat ćemo x koordinatu da odgovara aritm sredini pozicije toga i sljedećeg polja (umanjenoj za debljinu crte)
			if (stranaPloce == DOLJE || stranaPloce == GORE)
				sredina.x = (sredina.x + koordianteSljedecegPolja.x - DEBLJINA_CRNE_CRTE) / 2;
			else
				sredina.y = (sredina.y + koordianteSljedecegPolja.y - DEBLJINA_CRNE_CRTE) / 2;
			
			return sredina;
		}
		
		public function VratiSirinuPolja():Number
		{
			const DEBLJINA_CRNE_CRTE:Number = 1.1;  // 1.11px
			var sirina:Number;
			var stranaPloce = Math.floor(this.IndeksPolja / 10);  // strana ploče na kojoj se nalazi polje
			var koordianteSljedecegPolja:Point = Polja[(this.IndeksPolja + 1) % 40].Koordinate;
			
			if (stranaPloce == DOLJE || stranaPloce == GORE)
				sirina = Math.abs(this.Koordinate.x - koordianteSljedecegPolja.x) - DEBLJINA_CRNE_CRTE;
			else
				sirina = Math.abs(this.Koordinate.y - koordianteSljedecegPolja.y) - DEBLJINA_CRNE_CRTE;
				
			return sirina;
		}
		
		private function ZavrsiBacanje(e:Event = null):void
		{			
			if (e != null)
				e.currentTarget.removeEventListener("Posjed kupljen", ZavrsiBacanje);
		
			if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
				Monopoly.ZavrsiBacanje();
			else
				Monopoly.SakrijPokaziGumbZaKrajPoteza(true);
		}
	}
}
