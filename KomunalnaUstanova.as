package  {
	import flash.geom.Point;
	
	public class KomunalnaUstanova extends Posjed {
		private const JEDNA_USTANOVA:uint = 0;
		private const DVIJE_USTANOVE:uint = 1;
		private const FRAME_S_ELEKTROM:uint = 3;	// broj framea s karticama elektre i vodovoda u objektu "karticaPosjeda_mc"
		private const FRAME_S_VODOVODOM:uint = 4;
		private const POLJE_S_ELEKTROM:uint = 12;	// indeksi na ploči s poljima komunalnih ustanova
		private const POLJE_S_VODOVODOM:uint = 28;
		public static var KomunalneUstanove:Vector.<KomunalnaUstanova> = new Vector.<KomunalnaUstanova>();
		
		public function KomunalnaUstanova(nazivKomunalneUstanove:String, indeksKomunalneUstanoveNaPloci:uint, koordinate:Point) {
			var najamnine:Array = new Array();
			najamnine[JEDNA_USTANOVA] = 80;		// u ovom slučaju najamnine nisu fiksne, nego se množe sa brojem kockica
			najamnine[DVIJE_USTANOVE] = 200;
			
			super(nazivKomunalneUstanove, indeksKomunalneUstanoveNaPloci, koordinate, KOMUNALIJE_POLJE, 3000, najamnine, 1500);			
			KarticaPosjeda = IzradiKarticuPosjeda();
		}
		
		public function IzradiKarticuPosjeda():karticaPosjeda_mc
		{
			var kartica:karticaPosjeda_mc = new karticaPosjeda_mc();
			if (this.IndeksPolja == POLJE_S_ELEKTROM)  // ako se radi o polju s elektrom (inkeks polja je 12), izradit ćemo karticu za elektru. U suprotnom, izrađujemo karticu za vodovod
				kartica.gotoAndStop(FRAME_S_ELEKTROM);
			else
				kartica.gotoAndStop(FRAME_S_VODOVODOM);
				
			kartica.mouseChildren = false;
			return kartica;
		}
		
		public function IgracStaoNaKomunalnuUstanovu():void
		{
			// najprije moramo odrediti radi li se o vodovodu ili o elektri (jer su te 2 kartice na 2 različita frame-a u objektu "karticaPosjeda_mc"
			var frameKarticePosjeda:uint = (IndeksPolja == POLJE_S_ELEKTROM) ? FRAME_S_ELEKTROM : FRAME_S_VODOVODOM;
			if (this.Vlasnik == NIJE_KUPLJENO)
				KupiPosjed(this.NazivPolja, frameKarticePosjeda);
			else
			{
				if (! PodHipotekom && igrac_mc.IgracNaPotezu != this.Vlasnik)
					PlatiNajamninu();
				
				if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
					Monopoly.ZavrsiBacanje();
			}
		}
		
		private function PlatiNajamninu():void
		{
			// ako igrač koji je na potezu nije vlasnik željezničke stanice, morat će platit najamninu (već prije određeno). Ova funkcija samo simulira naplatu najamnine
			var najamnina:uint = kocka_mc.Kocke[0].currentFrame + kocka_mc.Kocke[1].currentFrame;	// za najamninu postavljamo zbroj brojeva na kockicama. Taj ćemo onda broj množiti sa 80 ili 200, ovisno o tome koliko vlasnik ima komunalnih ustanova
			
			// provjeravamo koliko komunalnih ustanova posjeduje vlasnik na čiju smo komunalnu ustanovu stali
			if (BrojKomunalnihUstanovaIstogVlasnika() == 1)
				najamnina *= 80;
			else
				najamnina *= 200;
				
			// igraču koji je stao na komunalnu ustanovu uzimamo novac, a vlasniku dajemo
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = this.Vlasnik;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= najamnina;
			igrac_mc.Igraci[this.Vlasnik].Novac += najamnina;
		}
		
		private function BrojKomunalnihUstanovaIstogVlasnika():uint
		{
			var trazeniVlasnik:uint = this.Vlasnik;
			var brojKomunalnihUstanova:uint = 0;
			
			for (var i:uint = 0; i < KomunalneUstanove.length; i++)
				if (KomunalneUstanove[i].Vlasnik == trazeniVlasnik)
					brojKomunalnihUstanova++;
					
			return brojKomunalnihUstanova;
		}
		
		public static function PronadjiIndeksUPoljuZeljznickihStanica(indeksKomunalneUstanoveNaPloci:uint):uint
		{
			// iz objekta tipa Polje dobili smo indeks polja s PLOČE na kojem se igrač zaustavio. Sada trebamo iz indeksa s PLOČE pronaći indeks u POLJU KOMUNALNIH USTANOVA, kako bi onda mogli baratati s tim poljem.
			// ovu funkciju poziva objekt tipa "Polje" kako bi utvrdio indeks komunalne ustanove u polju
			
			for (var i:uint = 0; i < KomunalneUstanove.length; i++)
				if (KomunalneUstanove[i].IndeksPolja == indeksKomunalneUstanoveNaPloci)
					return i;
					
			// ovaj return 100 je potreban samo zbog kompajlera! U biti, on ni ne treba jer će se gornji return svakako izvršiti
			return 100;
		}
	}
}
