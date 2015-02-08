package  {
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	public class Zemljiste extends Posjed {
		private const SAMO_ZEMLJISTE:uint = 0;
		private const JEDNA_KUCA:uint = 1;
		private const DVIJE_KUCE:uint = 2;
		private const TRI_KUCE:uint = 3;
		private const CETIRI_KUCE:uint = 4;
		private const HOTEL:uint = 5;
		private const FRAME_SA_ZEMLJISTEM:uint = 1;  // broj framea s karticom zemljišta u objektu "karticaPosjeda_mc"
		public static var UkupnoKucaPreostalo:uint = 32;
		public static var UkupnoHotelaPreostalo:uint = 12;
		
		public static var Zemljista:Vector.<Zemljiste> = new Vector.<Zemljiste>();
		public var CijenaKuce:uint;  // cijena jedne kuće. Cijena hotela jednaka je cijeni 5 kuća
		public var BrojKuca:uint = 0;	// 5 kuća označava hotel. Tako imamo posebnu konstantu HOTEL koja iznosi 5

		public function Zemljiste(nazivZemljista:String, indeksZemljistaNaPloci:uint, koordinate:Point, vrstaPolja:uint, cijena:uint, najamnina:uint, jednaKuca:uint, dvijeKuce:uint, triKuce:uint, cetiriKuce:uint, hotel:uint, cijenaKuce:uint) {
			var najamnine:Array = new Array();
			najamnine[SAMO_ZEMLJISTE] = najamnina;
			najamnine[JEDNA_KUCA] = jednaKuca;
			najamnine[DVIJE_KUCE] = dvijeKuce;
			najamnine[TRI_KUCE] = triKuce;
			najamnine[CETIRI_KUCE] = cetiriKuce;
			najamnine[HOTEL] = hotel;
			CijenaKuce = cijenaKuce;
			
			super(nazivZemljista, indeksZemljistaNaPloci, koordinate, vrstaPolja, cijena, najamnine, cijena / 2);
			KarticaPosjeda = IzradiKarticuPosjeda();
		}
		
		public static function PronadjiIndeksUPoljuZemljista(indeksZemljistaNaPloci:uint):uint
		{
			// iz objekta tipa Polje dobili smo indeks polja s PLOČE na kojem se igrač zaustavio. Sada trebamo iz indeksa s PLOČE pronaći indeks u POLJU ZEMLJIŠTA, kako bi onda mogli baratati s tim poljem.
			// ovu funkciju poziva objekt tipa "Polje" kako bi utvrdio indeks zemljišta u polju
		
			for (var i:uint = 0; i < Zemljista.length; i++)
				if (Zemljista[i].IndeksPolja == indeksZemljistaNaPloci)
					return i;
					
			// ovaj return 100 je potreban samo zbog kompajlera! U biti, on ni ne treba jer će se gornji return svakako izvršiti
			return 100;
		}
		
		public function IzradiKarticuPosjeda():karticaPosjeda_mc
		{
			const FRAME_S_POSJEDOM:uint = 1;
			var kartica:karticaPosjeda_mc = new karticaPosjeda_mc();
			kartica.gotoAndStop(FRAME_S_POSJEDOM);
			var boja:uint;	// označavat će boju zemljišta, tipa narančasta, smeđa, rozna, itd.
			switch (VrstaPolja)
			{
				case SMEDJE_POLJE: boja = 0x663a2b; break;
				case SVIJETLO_PLAVO_POLJE: boja = 0x9dc9da; break;
				case ROZNO_POLJE: boja = 0xc53883; break;
				case NARANCASTO_POLJE: boja = 0xe38629; break;
				case CRVENO_POLJE: boja = 0xd20000; break;
				case ZUTO_POLJE: boja = 0xeee003; break;
				case ZELENO_POLJE: boja = 0x10934e; break;
				case TAMNO_PLAVO_POLJE: boja = 0x005b91; break;
			}
			
			// mijenjamo boju pravokutnika na kartici zemljišta. Da bi to obavili, moramo koristiti objekt ColorTransform
			var transformacijaBoje:ColorTransform = new ColorTransform();
			transformacijaBoje.color = boja;
			kartica.Boja.transform.colorTransform = transformacijaBoje;
			
			// mijenjamo naziv kartice i cijene na njoj
			kartica.Naziv.text = NazivPolja.toUpperCase();
			kartica.Najamnina.text = Najamnine[SAMO_ZEMLJISTE].toString() + " Kn";
			kartica.JednaKuca.text = Najamnine[JEDNA_KUCA].toString() + " Kn";
			kartica.DvijeKuce.text = Najamnine[DVIJE_KUCE].toString() + " Kn";
			kartica.TriKuce.text = Najamnine[TRI_KUCE].toString() + " Kn";
			kartica.CetiriKuce.text = Najamnine[CETIRI_KUCE].toString() + " Kn";
			kartica.Hotel.text = Najamnine[HOTEL].toString() + " Kn";
			kartica.CijenaKuce.text = CijenaKuce.toString() + " Kn";
			kartica.CijenaHotela.text = kartica.CijenaKuce.text;	// isti je tekst uvijek za cijenu kuće i cijenu hotela
			kartica.VrijednostHipoteke.text = VrijednostHipoteke.toString() + " Kn";
			kartica.mouseChildren = false;
			
			return kartica;
		}
		
		public function IgracStaoNaZemljiste():void
		{
			if (this.Vlasnik == NIJE_KUPLJENO)
			{
				KupiPosjed(this.NazivPolja, FRAME_SA_ZEMLJISTEM);
			}
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
			var najamnina:uint;
			// ako igrač koji je na potezu nije vlasnik zemljišta, morat će platit najamninu (već prije određeno). Ova funkcija samo simulira naplatu najamnine
			
			// provjeravamo posjeduje li vlasnik zemljišta na koje smo stali također i sva ostala zemljišta te boje (i nijedno nije pod hipotekom). U tom slučaju plaćamo dvostruku cijenu. Međutim, taj uvjet vrijedi samo ako na posjedu na kojem smo stali nema kuća
			if (IgracImaSvaPoljaIsteBoje(this.VrstaPolja) && this.BrojKuca == SAMO_ZEMLJISTE)
				najamnina = this.Najamnine[SAMO_ZEMLJISTE] * 2;
			else
				najamnina = this.Najamnine[BrojKuca];
			
			// igraču na potezu oduzimamo svotu, dok vlasniku zemljišta dodjeljujemo tu svotu
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = this.Vlasnik;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= najamnina;
			igrac_mc.Igraci[this.Vlasnik].Novac += najamnina;
		}
		
		private function IgracImaSvaPoljaIsteBoje(odredjenaBoja:uint):Boolean
		{
			// ova funkcija provjerava pripadaju li svi posjedi jedne boje nekom igraču (dakle, svi posjedi samo jednom igraču). Ako je to istina i ako NIJEDNO od polja nije POD HIPOTKOM, vraća true
			
			var trazeniVlasnik:uint = this.Vlasnik;  // vlasnik za kojeg ispitujemo ima li sva polja iste boje. On je ujedno vlasnik i ovog polja (jer smo na njega nagazili)
			
			for (var i:uint = 0; i < Zemljista.length; i++)
				if (Zemljista[i].VrstaPolja == odredjenaBoja)
					if (Zemljista[i].Vlasnik != trazeniVlasnik || Zemljista[i].PodHipotekom)  // ako na samo jednom posjedu iste boje pronađemo da nije isti vlasnik, to znači da vlasnik nije vlasnik svih zemljišta iste boje
						return false;
						
			return true;
		}
		
		public function RavnomjernoIzgradjeneKuce(gradnja:Boolean):Boolean
		{
			var brojKuca:Array = new Array();	// ovo polje će sadržavati broj kuća na svakom zemljištu ove boje (dakle, integere)
			brojKuca.push(BrojKuca + (gradnja ? 1 : -1));  // u polje stavljamo broj kuća ovog zemljišta + 1 / -1 (ovisno jel se radi o gradnji ili rušenju). Tako ćemo moći testirati je li gradnja / rušenje ravnomjerno
			
			// krećemo se kroz polje zemljišta i tražimo ona zemljišta koja su iste boje kao i ovo. Kada nađemo, samo broj kuća (integer) s tog zemljišta prenesemo u ovo polje gore
			for (var i:uint = 0; i < Zemljista.length; i++)
				if (Zemljista[i].VrstaPolja == this.VrstaPolja && Zemljista[i] != this)	 // ako su iste boje, ali ako nisu jednaki posjedi
					brojKuca.push(Zemljista[i].BrojKuca);
			
			// provjeravamo je li gradnja ravnomjerna. Kako? Najprije sortiramo elemente vektora i potom, ako je razlika prvog i posljednjeg elementa veća od jedan, gradnja nije moguća. U suprotnom jest
			brojKuca.sort(Array.NUMERIC);
			if (Math.abs(brojKuca[0] - brojKuca[brojKuca.length - 1]) > 1)
				return false;
			else
				return true;
		}
	}
}
