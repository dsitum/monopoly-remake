package  {
	import flash.geom.Point;
	public class ZeljeznickaStanica extends Posjed {
		private const JEDNA_STANICA:uint = 0; 
		private const DVIJE_STANICE:uint = 1; 
		private const TRI_STANICE:uint = 2; 
		private const CETIRI_STANICE:uint = 3;
		private const FRAME_SA_ZELJEZNICKOM_STANICOM:uint = 2;  // broj framea s karticom željezničke stanice u objektu "karticaPosjeda_mc"
		public static var ZeljeznickeStanice:Vector.<ZeljeznickaStanica> = new Vector.<ZeljeznickaStanica>();
		
		public function ZeljeznickaStanica(nazivStanice:String, indeksStaniceNaPloci:uint, koordinate:Point) {
			var najamnine:Array = new Array();
			najamnine[JEDNA_STANICA] = 500;
			najamnine[DVIJE_STANICE] = 1000;
			najamnine[TRI_STANICE] = 2000;
			najamnine[CETIRI_STANICE] = 4000;
			
			super(nazivStanice, indeksStaniceNaPloci, koordinate, ZELJEZNICKA_STANICA_POLJE, 4000, najamnine, 2000);
			KarticaPosjeda = IzradiKarticuPosjeda();
		}
		
		public function IzradiKarticuPosjeda():karticaPosjeda_mc
		{
			var kartica:karticaPosjeda_mc = new karticaPosjeda_mc();
			kartica.gotoAndStop(FRAME_SA_ZELJEZNICKOM_STANICOM);
			kartica.Naziv.text = NazivPolja.toUpperCase();
			kartica.mouseChildren = false;
			return kartica;
		}
		
		public function IgracStaoNaZeljeznickuStanicu():void
		{
			if (this.Vlasnik == NIJE_KUPLJENO)
				KupiPosjed(this.NazivPolja, FRAME_SA_ZELJEZNICKOM_STANICOM);
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
			
			// provjeravamo koliko željezničkih stanica posjeduje vlasnik na čiju smo željezničku stanicu stali
			var brojZeljeznickihStanicaVlasnika = BrojZeljeznickihStanicaIstogVlasnika();
			// Oduzimamo igraču određenu svotu novca (koja je direktno povezana s brojem stanica koje posjeduje vlasnik na čiju smo stanicu stali)
			var najamnina = this.Najamnine[brojZeljeznickihStanicaVlasnika - 1];
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = this.Vlasnik;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= najamnina;
			igrac_mc.Igraci[this.Vlasnik].Novac += najamnina;
		}
		
		private function BrojZeljeznickihStanicaIstogVlasnika():uint
		{
			var trazeniVlasnik:uint = this.Vlasnik;
			var brojStanica:uint = 0;
			
			for (var i:uint = 0; i < ZeljeznickeStanice.length; i++)
				if (ZeljeznickeStanice[i].Vlasnik == trazeniVlasnik)
					brojStanica++;
					
			return brojStanica;
		}
		
		public static function PronadjiIndeksUPoljuZeljznickihStanica(indeksStaniceNaPloci):uint
		{
			// iz objekta tipa Polje dobili smo indeks polja s PLOČE na kojem se igrač zaustavio. Sada trebamo iz indeksa s PLOČE pronaći indeks u POLJU ŽELJEZNIČKIH STANICA, kako bi onda mogli baratati s tim poljem.
			// ovu funkciju poziva objekt tipa "Polje" kako bi utvrdio indeks željezničke stanice u polju
		
			for (var i:uint = 0; i < ZeljeznickeStanice.length; i++)
				if (ZeljeznickeStanice[i].IndeksPolja == indeksStaniceNaPloci)
					return i;
					
			// ovaj return 100 je potreban samo zbog kompajlera! U biti, on ni ne treba jer će se gornji return svakako izvršiti
			return 100;
		}
	}
}
