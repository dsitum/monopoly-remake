package  {
	public class KarticaSrece {
		public var IndeksKartice:uint;  // svaka kartica ima indeks prema kojem ju prepoznajemo
		public var TekstKartice:String;
		public var IzadjiteIzZatvora:Boolean;  // odgovara na pitanje radi li se o posebnoj kartici "Izađi iz zatvora"
		
		public function KarticaSrece(indeks:uint, tekst:String, izadjiteIzZatvora:Boolean = false)
		{
			IndeksKartice = indeks;
			TekstKartice = tekst;
			IzadjiteIzZatvora = izadjiteIzZatvora;
		}
	}
}
