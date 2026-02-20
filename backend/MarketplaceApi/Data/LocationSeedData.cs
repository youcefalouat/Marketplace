using MarketplaceApi.Models;

namespace MarketplaceApi.Data;

public static class LocationSeedData
{
    public static void SeedLocations(ApplicationDbContext db)
    {
        if (!db.Wilayas.Any())
        {
            var wilayas = GetWilayas();
            db.Wilayas.AddRange(wilayas);
            db.SaveChanges();
        }

        if (!db.Communes.Any())
        {
            var communes = GetCommunes();
            db.Communes.AddRange(communes);
            db.SaveChanges();
        }
    }

    private static List<Wilaya> GetWilayas()
    {
        return new List<Wilaya>
        {
            new() {  Code = "01", Name = "Adrar", ArName = "أدرار" },
            new() {  Code = "02", Name = "Chlef", ArName = "الشلف" },
            new() {  Code = "03", Name = "Laghouat", ArName = "الأغواط" },
            new() {  Code = "04", Name = "Oum El Bouaghi", ArName = "أم البواقي" },
            new() {  Code = "05", Name = "Batna", ArName = "باتنة" },
            new() {  Code = "06", Name = "Béjaïa", ArName = "بجاية" },
            new() {  Code = "07", Name = "Biskra", ArName = "بسكرة" },
            new() {  Code = "08", Name = "Bechar", ArName = "بشار" },
            new() {  Code = "09", Name = "Blida", ArName = "البليدة" },
            new() {  Code = "10", Name = "Bouira", ArName = "البويرة" },
            new() {  Code = "11", Name = "Tamanrasset", ArName = "تمنراست" },
            new() {  Code = "12", Name = "Tébessa", ArName = "تبسة" },
            new() {  Code = "13", Name = "Tlemcen", ArName = "تلمسان" },
            new() {  Code = "14", Name = "Tiaret", ArName = "تيارت" },
            new() {  Code = "15", Name = "Tizi Ouzou", ArName = "تيزي وزو" },
            new() {  Code = "16", Name = "Alger", ArName = "الجزائر" },
            new() {  Code = "17", Name = "Djelfa", ArName = "الجلفة" },
            new() {  Code = "18", Name = "Jijel", ArName = "جيجل" },
            new() {  Code = "19", Name = "Sétif", ArName = "سطيف" },
            new() {  Code = "20", Name = "Saïda", ArName = "سعيدة" },
            new() {  Code = "21", Name = "Skikda", ArName = "سكيكدة" },
            new() {  Code = "22", Name = "Sidi Bel Abbès", ArName = "سيدي بلعباس" },
            new() {  Code = "23", Name = "Annaba", ArName = "عنابة" },
            new() {  Code = "24", Name = "Guelma", ArName = "قالمة" },
            new() {  Code = "25", Name = "Constantine", ArName = "قسنطينة" },
            new() {  Code = "26", Name = "Médéa", ArName = "المدية" },
            new() {  Code = "27", Name = "Mostaganem", ArName = "مستغانم" },
            new() {  Code = "28", Name = "M'Sila", ArName = "المسيلة" },
            new() {  Code = "29", Name = "Mascara", ArName = "معسكر" },
            new() {  Code = "30", Name = "Ouargla", ArName = "ورقلة" },
            new() {  Code = "31", Name = "Oran", ArName = "وهران" },
            new() {  Code = "32", Name = "El Bayadh", ArName = "البيض" },
            new() {  Code = "33", Name = "Illizi", ArName = "إليزي" },
            new() {  Code = "34", Name = "Bordj Bou Arréridj", ArName = "برج بوعريريج" },
            new() {  Code = "35", Name = "Boumerdès", ArName = "بومرداس" },
            new() {  Code = "36", Name = "El Tarf", ArName = "الطارف" },
            new() {  Code = "37", Name = "Tindouf", ArName = "تندوف" },
            new() {  Code = "38", Name = "Tissemsilt", ArName = "تيسمسيلت" },
            new() {  Code = "39", Name = "El Oued", ArName = "الوادي" },
            new() {  Code = "40", Name = "Khenchela", ArName = "خنشلة" },
            new() {  Code = "41", Name = "Souk Ahras", ArName = "سوق أهراس" },
            new() {  Code = "42", Name = "Tipaza", ArName = "تيبازة" },
            new() {  Code = "43", Name = "Mila", ArName = "ميلة" },
            new() {  Code = "44", Name = "Aïn Defla", ArName = "عين الدفلى" },
            new() {  Code = "45", Name = "Naâma", ArName = "النعامة" },
            new() {  Code = "46", Name = "Aïn Témouchent", ArName = "عين تموشنت" },
            new() {  Code = "47", Name = "Ghardaïa", ArName = "غرداية" },
            new() {  Code = "48", Name = "Relizane", ArName = "غليزان" },
            new() {  Code = "49", Name = "Timimoun", ArName = "تيميمون" },
            new() {  Code = "50", Name = "Bordj Badji Mokhtar", ArName = "برج باجي مختار" },
            new() {  Code = "51", Name = "Ouled Djellal", ArName = "أولاد جلال" },
            new() {  Code = "52", Name = "Béni Abbès", ArName = "بني عباس" },
            new() {  Code = "53", Name = "In Salah", ArName = "عين صالح" },
            new() {  Code = "54", Name = "In Guezzam", ArName = "عين قزام" },
            new() {  Code = "55", Name = "Touggourt", ArName = "تقرت" },
            new() {  Code = "56", Name = "Djanet", ArName = "جانت" },
            new() {  Code = "57", Name = "El M'Ghair", ArName = "المغير" },
            new() {  Code = "58", Name = "El Meniaa", ArName = "المنيعة" },
        };
    }

    private static List<Commune> GetCommunes()
    {
        var communes = new List<Commune>();
        int id = 1;

        // Wilaya 01 - Adrar
        AddCommunes(communes, ref id, 1, "ADRAR", "REGGANE", "AOULEF", "TIT", "TSABIT", "SALI", "TAMANTIT", "BOUDA", "OULED AHMED TIMMI", "IN ZGHMIR", "FENOUGHIL", "SEBAA", "TIMEKTEN", "AKABLI");
        // Wilaya 02 - Chlef
        AddCommunes(communes, ref id, 2, "CHLEF", "TENES", "BENAIRIA", "EL KARIMIA", "HARCHOUN", "SENDJAS", "OULED BENABDELKADER", "SOBHA", "OULED FARES", "CHETTIA", "ABOU EL HASSAN", "OUED SLY", "BOUKADIR", "BENI RACHED", "TALASSA", "HERENFA", "OUED FODDA", "OULED ABBES", "OUED GOUSSINE", "DAHRA", "TAOUGRITE", "TAJENA", "BREIRA", "EL HADJADJ", "MOUSSADEK", "ZEBOUDJA", "BOUZEGHAIA", "BENI HOUA", "OUM DROU", "SIDI AKKACHA", "SIDI ABDERRAHMANE", "EL MARSA");
        // Wilaya 03 - Laghouat
        AddCommunes(communes, ref id, 3, "LAGHOUAT", "KSAR EL HIRANE", "BENACER BENCHOHRA", "SIDI MAKHLOUF", "HASSI DELAA", "HASSI RMEL", "AIN MADHI", "TADJEMOUT", "EL KHENEG", "GUELTAT SIDI SAAD", "AIN SIDI ALI", "EL BEIDHA", "BRIDA", "EL GHICHA", "HADJ MECHRI", "SEBGAG", "AFLOU", "OUED M'ZI", "OUED MORRA", "OUBANE", "SIDI BOUZID", "EL ASSAFIA", "TAOUIALA");
        // Wilaya 04 - Oum El Bouaghi
        AddCommunes(communes, ref id, 4, "OUM EL BOUAGHI", "AIN BEIDA", "AIN M'LILA", "AIN KERCHA", "AIN FAKROUN", "AIN BABOUCHE", "AIN ZITOUN", "AIN DISS", "BERRICHE", "BIR CHOUHADA", "DHALA", "EL BELALA", "EL DJAZIA", "EL FEDJOUDJ BOUGHRARA SAOU", "EL HARMILIA", "FKIRINA", "HANCHIR TOUMGHANI", "KSAR SBAHI", "MESKIANA", "OUED NINI", "OULED GACEM", "OULED HAMLA", "OULED ZOUAI", "RAHIA", "SIGUS", "SOUK NAAMANE", "ZORG", "EL AMIRIA");
        // Wilaya 05 - Batna
        AddCommunes(communes, ref id, 5, "BATNA", "ARRIS", "BARIKA", "AIN TOUTA", "AIN DJASSER", "OUED CHAABA", "OUED EL MA", "OUED TAGA", "OUYOUN EL ASSAFIR", "RAHBAT", "RAS EL AIOUN", "SEFIANE", "SEGGANA", "SERIANA", "TALKHAMT", "TAXLENT", "TAZOULT", "TENIET EL ABED", "TIGHANIMINE", "TIGHERGHAR", "TILATOU", "TIMGAD", "T'KOUTT", "ZANAT EL BEIDA", "AIN YAGOUT", "AMDOUKAL", "BEN FOUDHALA EL HAKANIA", "BITAM", "BOULHILAT", "BOUMAGUEUR", "BOUMIA", "BOUZINA", "DJERMA", "DJEZZAR", "EL HASSI", "EL MADHER", "FESDIS", "FOUM TOUB", "GHASSIRA", "GOSBAT", "GUIGBA", "ICHMOUL", "INOUGHISSEN", "KIMMEL", "KSAR BELLEZMA", "LAZROU", "LEMSANE", "MAAFA", "MENAA", "MEROUANA", "N'GAOUS", "OULED AMMAR", "OULED AOUF", "OULED FADEL", "OULED SELLAM", "OULED SI SLIMANE", "CHEMORA", "CHIR", "HIDOUSSA", "AZIL ABD EL KADER");
        // Wilaya 06 - Béjaïa
        AddCommunes(communes, ref id, 6, "BEJAIA", "AKBOU", "AMIZOUR", "EL KSEUR", "SIDI AICH", "KHERRATA", "SOUK EL THENINE", "SOUK OUFELLA", "TALA HAMZA", "TAMOKRA", "TAMRIDJET", "TAOURIRT IGHIL", "TASKRIOUT", "TAZMALT", "THINABDHER", "TIBANE", "TICHI", "TIFRA", "TIMZRIT", "TIZI N'BERBER", "TOUDJA", "ADEKAR", "AIT RIZINE", "AIT SMAIL", "AKFADOU", "AMALOU", "AOKAS", "BARBACHA", "BENI KSILA", "BENI MAOUCH", "BENI MELIKECHE", "BOUDJELLIL", "BOUHAMZA", "BOUKHELIFA", "CHELATA", "CHEMINI", "DARGUINA", "DRAA KAID", "LEFLAYE", "FERRAOUN", "IFELAIN ILMATHEN", "IGHIL ALI", "IGHRAM", "KENDIRA", "MELBOU", "M'CISNA", "OUED GHIR", "OUZELLAGUEN", "SEDDOUK", "SEMAOUN", "SIDI AYAD", "BENI DJELLIL");
        // Wilaya 07 - Biskra
        AddCommunes(communes, ref id, 7, "BISKRA", "SIDI OKBA", "TOLGA", "EL KANTARA", "EL OUTAYA", "SIDI KHALED", "FOUGHALA", "DJEMORAH", "M'CHOUNECHE", "LIOWA", "OURLAL", "AIN NAGA", "AIN ZAATOUT", "BORDJ BEN AZZOUZ", "BOUCHAGROUN", "BRANIS", "CHETMA", "EL FEIDH", "EL GHROUS", "EL HADJEB", "EL HAOUCH", "KHENGUET SIDI NADJI", "LICHANA", "MEKHADMA", "M'LILI", "OUMACHE", "ZERIBET EL OUED", "MEZIRAA");
        // Wilaya 08 - Bechar
        AddCommunes(communes, ref id, 8, "BECHAR", "KENADSA", "ABADLA", "BENI OUNIF", "TAGHIT", "IGLI", "LAHMAR", "MERIDJA", "BOUKAIS", "MOUGHEUL", "TABALBALA", "ERG FERRADJ");
        // Wilaya 09 - Blida
        AddCommunes(communes, ref id, 9, "BLIDA", "BOUFARIK", "MOUZAIA", "OULED YAICH", "EL AFFROUN", "BOUGARA", "BOUINAN", "CHREA", "LARBAA", "BENI MERED", "OUED EL ALLEUG", "SOUMAA", "AIN ROMANA", "CHIFA", "HAMMAM MELOUANE", "BOUARFA", "BEN KHELLIL", "BENI TAMOU", "CHEBLI", "DJEBABRA", "OUED DJER", "OULED SELAMA", "SOUHANE", "GUERROUAOU");
        // Wilaya 10 - Bouira
        AddCommunes(communes, ref id, 10, "BOUIRA", "SOUR EL GHOZLANE", "LAKHDARIA", "AIN BESSEM", "M'CHEDALLAH", "BECHLOUL", "EL HACHIMIA", "BORDJ OUKHRISS", "HAIZER", "KADIRIA", "BIR GHBALOU", "AHL EL KSAR", "AGHBALOU", "HANIF", "AIN EL HADJAR", "AIN LALOUI", "AIT MANSOUR", "AOMAR", "AIN TURK", "AIT LAAZIZ", "BOUDERBALA", "BOUKRAM", "DECHMIA", "DIRAH", "DJEBAHIA", "EL HAKIMIA", "EL ADJIBA", "EL KHEBOUZIA", "EL MOKRANI", "EL ASNAM", "GUERROUMA", "HADJERA ZERGA", "MEZDOUR", "MAALA", "MAAMORA", "OUED EL BERDI", "OULED RACHED", "RAOURAOUA", "RIDANE", "SAHARIDJ", "SOUK EL KHEMIS", "TAGUEDIT", "ZBARBAR", "CHORFA", "TAGHZOUT");
        // Wilaya 11 - Tamanrasset
        AddCommunes(communes, ref id, 11, "TAMENRASSET", "ABALESSA", "IDLES", "AIN AMGUEL", "TAZROUK");
        // Wilaya 12 - Tébessa
        AddCommunes(communes, ref id, 12, "TEBESSA", "BIR EL ATER", "CHERIA", "EL AOUINET", "MORSOTT", "OUENZA", "EL KOUIF", "HAMMAMET", "NEGRINE", "EL OGLA", "BEKKARIA", "BOULHAF DYR", "AIN ZERGA", "BIR EL MOKADEM", "BOUKHADRA", "EL MA EL BIODH", "EL MERIDJ", "EL MEZERAA", "EL OGLA EL MALHA", "FERKANE", "GUORRIGUER", "LAHOUIDJBET", "OUM ALI", "SAF SAF EL OUESRA", "STAH GUENTIS", "THLIDJENE", "BEDJENE", "BIR DHEHEB");
        // Wilaya 13 - Tlemcen
        AddCommunes(communes, ref id, 13, "TLEMCEN", "MAGHNIA", "GHAZAOUET", "REMCHI", "NEDROMA", "HENNAYA", "SEBDOU", "BAB EL ASSA", "MANSOURAH", "SABRA", "OULED MIMOUN", "BENSEKRANE", "BAB EL KHEMIS", "IMAMA", "SIDI OTHMANE", "TERNI BENI HEDIEL", "AIN GHORABA", "BENI MESTER", "CHETOUANE", "AIN FEZZA", "AMIEUR", "OUED LAKHDAR", "BENI SEMIEL", "AIN TALLOUT", "AIN NEHALA", "SIDI ABDELLI", "BENI OUARSOUS", "AIN YOUCEF", "SEBBAA CHIOUKH", "EL FEHOUL", "ZENATA", "OULED RIYAH", "SOUAHLIA", "TIANET", "DAR YAGHMOURACENE", "DJEBALA", "FELLAOUCENE", "AIN FETAH", "AIN KEBIRA", "HAMMAM BOUGHRARA", "BENI BOUSSAID", "SIDI MEDJAHED", "BOUHLOU", "EL GOR", "EL ARICHA", "SIDI DJILLALI", "ELBOUIHI", "BENI SNOUS", "AZAILS", "BENI BAHDEL", "SOUANI", "SOUK TLATA", "MARSA BEN M'HIDI", "MSIRDA FOUAGA", "HONAINE", "BENI KHELLAD");
        // Wilaya 14 - Tiaret
        AddCommunes(communes, ref id, 14, "TIARET", "SOUGUEUR", "FRENDA", "KSAR CHELLALA", "AIN DEHEB", "MAHDIA", "OUED LILLI", "MECHRAA SAFA", "RAHOUIA", "HAMADIA", "MEGHILA", "DAHMOUNI", "AIN BOUCHEKIF", "AIN EL HADID", "AIN KERMES", "AIN ZARIT", "BOUGARA", "CHEHAIMA", "DJEBILET ROSFA", "DJILLALI BEN AMAR", "FAIDJA", "GUERTOUFA", "MADNA", "MEDRISSA", "MEDROUSSA", "MELLAKOU", "NADORAH", "NAIMA", "SEBT", "SERGHINE", "SI ABDELGHANI", "SIDI ALI MELLAL", "SIDI BAKHTI", "SIDI HOSNI", "TAGDEMT", "TAKHEMARET", "TIDDA", "TOUSNINA", "ZMALET EL EMIR ABDELKADER", "RECHAIGA", "SEBAINE", "SIDI ABDERRAHMANE");
        // Wilaya 15 - Tizi Ouzou
        AddCommunes(communes, ref id, 15, "TIZI OUZOU", "AZAZGA", "AIN EL HAMMAM", "DRAA EL MIZAN", "LARBA NATH IRATEN", "DRAA BEN KHEDDA", "TIGZIRT", "OUAGUENOUN", "BOGHNI", "MEKLA", "BENI DOUALA", "MAATKA", "OUADHIA", "BOUZGUEN", "AZEFFOUN", "IFERHOUNENE", "DJEBEL AISSA MIMOUN", "ABI YOUCEF", "AGHNI GOUGHRAN", "AGHRIB", "AIN ZAOUIA", "AIT AGGOUACHA", "AIT BOUADOU", "AIT-BOUMAHDI", "AIT CHAFFAA", "AIT KHELILI", "AIT MAHMOUD", "AIT OUMALOU", "AIT TOUDERT", "AIT YAHIA", "AIT YAHIA MOUSSA", "AKBIL", "AKERROU", "ASSI YOUCEF", "BENI AISSI", "BENI YENNI", "BENI ZIKI", "BENI ZMENZER", "BOUDJIMA", "BOUNOUH", "FREHA", "FRIKAT", "IBOUDRAREN", "IDJEUR", "IFIGHA", "IFLISSEN", "ILLILTEN", "ILOULA OUMALOU", "IMSOUHAL", "IRDJEN", "MAKOUDA", "MECHTRASS", "MIZRANA", "M'KIRA", "OUACIF", "SIDI NAAMANE", "SOUK EL THENINE", "SOUAMAA", "TADMAIT", "TIMIZART", "TIRMITINE", "TIZI GHENIF", "TIZI N'THLATA", "TIZI RACHED", "YAKOURENE", "YATAFENE", "ZEKRI");
        // Wilaya 16 - Alger
        AddCommunes(communes, ref id, 16, "ALGER CENTRE", "SIDI M'HAMED", "EL MADANIA", "EL MOURADIA", "BAB EL OUED", "CASBAH", "BOLOGHINE IBNOU ZIRI", "OUED KORICHE", "RAIS HAMIDOU", "EL MAGHARIA", "MOHAMED BELOUIZDAD", "HUSSEIN DEY", "KOUBA", "BEN AKNOUN", "BENI MESSOUS", "BOUZAREAH", "EL BIAR", "BIR MOURAD RAIS", "BIRKHADEM", "DJASR KASENTINA", "HYDRA", "SAOULA", "BACHEDJERAH", "BOUROUBA", "EL HARRACH", "OUED SMAR", "AIN TAYA", "BAB EZZOUAR", "BORDJ EL BAHRI", "BORDJ EL KIFFAN", "DAR EL BEIDA", "EL MARSA", "MOHAMMADIA", "AIN BENIAN", "CHERAGA", "DELY IBRAHIM", "OULED FAYET", "EL HAMMAMET", "MAHELMA", "RAHMANIA", "SOUIDANIA", "STAOUELI", "ZERALDA", "BABA HASSEN", "DOUERA", "DRARIA", "EL ACHOUR", "KHRAICIA", "BIRTOUTA", "OULED CHEBEL", "TESSALA EL MERDJA", "BARAKI", "LES EUCALYPTUS", "SIDI MOUSSA", "H'RAOUA", "REGHAIA", "ROUIBA", "BAINS ROMAINS");
        // Wilaya 17 - Djelfa
        AddCommunes(communes, ref id, 17, "DJELFA", "MESSAAD", "AIN OUSSERA", "HASSI BAHBAH", "CHAREF", "MOUADJEBAR", "BIRINE", "SIDI LADJEL", "HAD SAHARY", "AIN EL IBEL", "DAR CHIOUKH", "FAIDH EL BOTMA", "AIN CHOUHADA", "AIN FEKA", "AIN MAABED", "AMOURAH", "BENHAR", "BENI YAGOUB", "BOUIRA LAHDAB", "DOUIS", "EL GUEDID", "EL IDRISSIA", "EL KHEMIS", "GUERNINI", "GUETTARA", "HASSI EL EUCH", "HASSI FEDOUL", "M'LILIHA", "OUM LAADHAM", "SED RAHAL", "SELMANA", "SIDI BAIZID", "TADMIT", "ZAAFRANE", "ZACCAR", "DELDOUL");
        // Wilaya 18 - Jijel
        AddCommunes(communes, ref id, 18, "JIJEL", "EL MILIA", "TAHER", "CHEKFA", "EL ANCER", "ZIAMMA MANSOURIAH", "SIDI MAAROUF", "SETTARA", "TEXENA", "DJIMLA", "SELMA BENZIADA", "KAOUS", "BORDJ TAHER", "BOUSSIF OULED ASKEUR", "BOUDRIA BENI YADJIS", "BOURAOUI BELHADEF", "CHAHNA", "DJEMA BENI HABIBI", "EL AOUANA", "EL KENNAR NOUCHFI", "EMIR ABDELKADER", "ERRAGUENE", "GHEBALA", "KEMIR OUED ADJOUL", "OUADJANA", "OULED RABAH", "OULED YAHIA KHADROUCH", "SIDI ABDELAZIZ", "SIDI MAAROUF");
        // Wilaya 19 - Sétif
        AddCommunes(communes, ref id, 19, "SETIF", "EL EULMA", "AIN OULMANE", "AIN ARNAT", "BOUGAA", "AIN EL KEBIRA", "DJEMILA", "AMOUCHA", "EL OURICIA", "AIN AZAL", "BOUANDAS", "BABOR", "GUENZET", "BENI AZIZ", "AIN ABESSA", "AIN LAHDJAR", "AIN LEGRAJ", "AIN ROUA", "AIN SEBT", "AIT NAOUAL MEZADA", "AIT TIZI", "BAZER SAKRA", "BEIDHA BORDJ", "BELAA", "BENI CHEBANA", "BENI FOUDA", "BENI HOCINE", "BENI OUARTILANE", "BIR EL ARCH", "BIR HADDADA", "BOUSSELAM", "BOUTALEB", "DEHAMCHA", "DRAA KEBILA", "GUELLAL", "GUELTA ZERKA", "GUIDJEL", "HAMMA", "HAMMAM GUERGOUR", "HARBIL", "KSAR EL ABTAL", "MAAOUIA", "MAOUAKLANE", "MEZLOUG", "OUED EL BARAD", "OULED ADDOUANE", "OULED SABOR", "OULED SI AHMED", "OULED TEBBEN", "ROSFA", "SALAH BEY", "SERDJ EL GHOUL", "TACHOUDA", "TALAIFACENE", "TAYA", "TELLA", "TIZI N'BECHAR", "EL OULDJA", "HAMMAM ESOUKHNA");
        // Wilaya 20 - Saïda
        AddCommunes(communes, ref id, 20, "SAIDA", "YOUB", "SIDI BOUBEKEUR", "EL HASSASNA", "OULED BRAHIM", "AIN SOLTANE", "DOUI THABET", "SIDI AMAR", "MOULAY LARBI", "AIN SEKHOUNA", "HOUNET", "OULED KHALED", "SIDI AHMED", "TIRCINE", "AIN EL HADJAR", "MAAMORA");
        // Wilaya 21 - Skikda
        AddCommunes(communes, ref id, 21, "SKIKDA", "AZZABA", "EL HARROUCH", "COLLO", "TAMALOUS", "AIN ZOUIT", "OUM TOUB", "RAMDANE DJAMEL", "SIDI MEZGHICHE", "EL HADAIK", "AIN BOUZIANE", "AIN CHERCHAR", "BEKKOUCHE LAKHDAR", "BENI OULBANE", "BENI ZID", "BOUCHTATA", "CHERAIA", "DJENDEL SAADI MOHAMED", "EL GHEDIR", "EL MARSA", "EMDJEZ EDCHICH", "ES SEBT", "FIL FILA", "HAMADI KROUMA", "KANOUA", "KERKERA", "KHENEG MAYOUM", "OUED ZEHOUR", "OULDJA BOULBALLOUT", "OULED ATTIA", "OULED HEBABA", "SALAH BOUCHAOUR", "ZERDAZAS", "ZITOUNA", "AIN KECHRA", "BEIN EL OUIDEN", "BENI BACHIR", "BENAZOUZ");
        // Wilaya 22 - Sidi Bel Abbès
        AddCommunes(communes, ref id, 22, "SIDI BEL ABBES", "SFISSEF", "TELAGH", "TENIRA", "TESSALA", "MARHOUM", "AIN EL BERD", "RAS EL MA", "SIDI ALI BENYOUB", "MOSTEFA BEN BRAHIM", "MOULAY SLISSEN", "AIN ADDEN", "AIN KADA", "AIN THRID", "AIN TINDAMINE", "AMARNAS", "BADREDINE EL MOKRANI", "BELARBI", "BEN BADIS", "BENACHIBA CHELIA", "BIR EL HAMMAM", "BOUDJEBAA EL BORDJ", "BOUKHANAFIS", "CHETOUANE BELAILA", "DHAYA", "EL HACAIBA", "HASSI DAHOU", "HASSI ZEHANA", "LAMTAR", "MAKEDRA", "M'CID", "MERINE", "MEZAOUROU", "OUED SEBAA", "OUED SEFIOUN", "OUED TAOURIRA", "REDJEM DEMOUCHE", "SEHALA THAOURA", "SIDI BRAHIM", "SIDI CHAIB", "SIDI DAHOU DE ZAIRS", "SIDI HAMADOUCHE", "SIDI KHALED", "SIDI LAHCENE", "SIDI YACOUB", "TAOUDMOUT", "TEGHALIMET", "TILMOUNI", "ZEROUALA", "SIDI ALI BOUSSIDI", "TABIA");
        // Wilaya 23 - Annaba
        AddCommunes(communes, ref id, 23, "ANNABA", "EL HADJAR", "EL BOUNI", "BERRAHEL", "CHETAIBI", "CHEURFA", "OUED EL ANEB", "SERAIDI", "TREAT", "AIN BERDA", "EULMA", "SIDI AMAR");
        // Wilaya 24 - Guelma
        AddCommunes(communes, ref id, 24, "GUELMA", "OUED ZENATI", "BOUCHEGOUF", "HELIOPOLIS", "HAMMAM DEBAGH", "AIN MAKHLOUF", "DJEBALA KHEMISSI", "HAMMAM N'BAIL", "AIN BEN BEIDA", "AIN LARBI", "AIN REGGADA", "AIN SANDEL", "BELKHIR", "BEN DJARAH", "BENI MEZLINE", "BORDJ SABAT", "BOU HACHANA", "BOU HAMDANE", "BOUATI MAHMOUD", "BOUMAHRA AHMED", "DAHOUARA", "EL FEDJOUDJ", "GUELAAT BOU SBAA", "MEDJEZ AMAR", "MEDJEZ SFA", "NECHMAYA", "OUED CHEHAM", "OUED FRAGHA", "RAS EL AGBA", "ROKNIA", "SALAOUA ANNOUNA", "TAMLOUKA", "HOUARI BOUMEDIENNE", "LEKHZARA");
        // Wilaya 25 - Constantine
        AddCommunes(communes, ref id, 25, "CONSTANTINE", "EL KHROUB", "AIN SMARA", "HAMMA BOUZIANE", "DIDOUCHE MOURAD", "ZIGHOUD YOUCEF", "AIN ABID", "BENI HAMIDEN", "OULED RAHMOUNE", "MESSAOUD BOUDJERIOU", "IBN ZIAD", "BEN BADIS");
        // Wilaya 26 - Médéa
        AddCommunes(communes, ref id, 26, "MEDEA", "BERROUAGHIA", "KSAR EL BOUKHARI", "TABLAT", "AIN BOUCIF", "CHAHBOUNIA", "OUAMRI", "BENI SLIMANE", "OULED ANTAR", "OUZERA", "EL OMARIA", "SEGHOUANE", "SI MAHDJOUB", "OULED BRAHIM", "BOUGHEZOUL", "AIN OU KSIR", "AISSAOUIA", "AZIZ", "BAATA", "BENCHICAO", "BIR BEN LAABED", "BOGHAR", "BOUAICHE", "BOUAICHOUNE", "BOUCHRAHIL", "BOUSKENE", "CHELALET EL ADHAOURA", "CHENIGUEL", "DERRAG", "DEUX BASSINS", "DJOUAB", "DRAA ESSAMAR", "EL AZIZIA", "EL GUELBELKEBIR", "EL HAMDANIA", "EL OUINET", "HANNACHA", "KEF LAKHDAR", "KHAMS DJOUAMAA", "MEGHRAOUA", "MEDJEBAR", "MFATHA", "MEZERENA", "MIHOUB", "OUED HARBIL", "OULED BOUACHRA", "OULED DEIDE", "OULED HELLAL", "OULED MAAREF", "OUM EL DJALIL", "REBAIA", "SANEG", "SEDRAIA", "SIDI DAMED", "SIDI ERRABIA", "SIDI ZAHAR", "SIDI ZIANE", "SOUAGUI", "TAFRAOUT", "TAMESGUIDA", "TLATET EDDOUAIR", "ZOUBIRIA", "TIZI MAHDI", "SIDI NAAMANE");
        // Wilaya 27 - Mostaganem
        AddCommunes(communes, ref id, 27, "MOSTAGANEM", "AIN TADLES", "SIDI LAKHDAR", "HASSI MAAMECHE", "ACHAACHA", "SIDI ALI", "AIN NOUISSY", "KHEIREDINE", "AIN BOUDINAR", "MAZAGRAN", "FORNAKA", "MANSOURAH", "ABDELMALEK RAMDANE", "AIN SIDI CHERIF", "BOUGUIRAT", "EL HASSIANE", "HADJADJ", "KHADRA", "MESRA", "NEKMARIA", "OUED EL KHEIR", "OULED BOUGHALEM", "OULED MAALLAH", "SAFSAF", "SAYADA", "SIDI BELLATER", "SIRAT", "SOUAFLIA", "SOUR", "STIDIA", "TAZGAIT", "MEZGHRANE", "TOUAHRIA");
        // Wilaya 28 - M'Sila
        AddCommunes(communes, ref id, 28, "MSILA", "BOU SAADA", "SIDI AISSA", "AIN EL MELH", "HAMMAM DHALAA", "MAGRA", "KHOUBANA", "DJEBEL MESSAAD", "OULED DERRADJ", "BERHOUM", "MEDJEDEL", "BEN SROUR", "CHELLAL", "OULED SIDI BRAHIM", "AIN EL HADJEL", "AIN ERRICH", "AÏN FARES", "AIN KHADRA", "BELAIBA", "BENI ILMANE", "BENZOUH", "BIR FODA", "BOUTI SAYAH", "DEHAHNA", "EL HAMEL", "EL HOUAMED", "MAADID", "MAARIF", "M'CIF", "M'TARFA", "OUANOUGHA", "OULED ADDI GUEBALA", "OULED MADHI", "OULED MANSOUR", "OULED SLIMANE", "OULTENE", "SIDI AMEUR", "SIDI HADJERES", "SLIM", "TAMSA", "TARMOUNT", "ZARZOUR", "KHETTOUTI SED ELDJIR", "MENAA", "SOUAMAA", "MAHAMED BOUDIAF");
        // Wilaya 29 - Mascara
        AddCommunes(communes, ref id, 29, "MASCARA", "SIG", "MOHAMMADIA", "Tighennif", "BOU HANIFIA", "AIN FARES", "GHRISS", "OGGAZ", "OUED TARIA", "EL BORDJ", "AOUF", "EL HACHEM", "AIN FEKAN", "AÏN FERAH", "ALAIMIA", "BENIAN", "BOU HENNI", "EL GAADA", "EL GHOMRI", "GUETTENA", "MATEMORE", "EL KEURT", "EL MENAOUER", "FERRAGUIG", "FROHA", "GHARROUS", "GUERDJOUM", "EL MAMOUNIA", "HACINE", "KHALOUIA", "MAKDHA", "MAOUSSA", "NESMOT", "OUED EL ABTAL", "RAS AIN AMIROUCHE", "SEDJERARA", "SEHAILIA", "SIDI ABDELDJEBAR", "SIDI ABDELMOUMENE", "SIDI KADA", "SIDI BOUSSAID", "TEGHENIF", "TIZI", "ZAHANA", "CHORFA", "ZELAMTA", "MOCTADOUZ");
        // Wilaya 30 - Ouargla
        AddCommunes(communes, ref id, 30, "OUARGLA", "HASSI MESSAOUD", "N'GOUSSA", "ROUISSAT", "SIDI KHOUILED", "EL BORMA", "HASSI BEN ABDALLAH", "AIN BEIDA");
        // Wilaya 31 - Oran
        AddCommunes(communes, ref id, 31, "ORAN", "ES SENIA", "BIR EL DJIR", "AIN TURK", "ARZEW", "GDYEL", "BETHIOUA", "AIN BIYA", "OUED TLELAT", "BOUTLELIS", "BOUSFER", "SIDI CHAMI", "HASSI BOUNIF", "MERS EL KEBIR", "EL BRAYA", "BEN FREHA", "HASSI BEN OKBA", "MESSERGHIN", "AIN KERMA", "EL KARMA", "HASSI MEFSOUKH", "MARSAT EL HADJADJ", "SIDI BEN YABKA", "TAFRAOUI");
        // Wilaya 32 - El Bayadh
        AddCommunes(communes, ref id, 32, "EL BAYADH", "BREZINA", "EL ABIODH SIDI CHEIKH", "BOUGTOUB", "BOUALEM", "AIN EL ORAK", "ARBAOUAT", "BOUSSEMGHOUN", "CHEGUIG", "CHELLALA", "EL BNOUD", "EL KHEITHER", "EL MEHARA", "GHASSOUL", "KEF EL AHMAR", "KRAKDA", "ROGASSA", "SIDI TIFOUR", "STITTEN", "TOUSMOULINE", "SIDI AMEUR");
        // Wilaya 33 - Illizi
        AddCommunes(communes, ref id, 33, "ILLIZI", "IN AMENAS", "DEBDEB", "BORDJ OMAR DRISS");
        // Wilaya 34 - Bordj Bou Arréridj
        AddCommunes(communes, ref id, 34, "BORDJ BOU ARRERIDJ", "RAS EL OUED", "BORDJ GHDIR", "MEDJANA", "MANSOURA", "EL ACHIR", "BORDJ ZEMOURA", "AIN TAGHROUT", "DJAAFRA", "BIR KASDALI", "EL HAMADIA", "AIN TESRA", "BELIMOUR", "BEN DAOUD", "COLLA", "EL ANASEUR", "EL MAIN", "EL M'HIR", "GHILASSA", "HARAZA", "HASNAOUA", "KHELIL", "KSOUR", "OULED BRAHEM", "OULED DAHMANE", "RABTA", "SIDI EMBAREK", "TAFREG", "TAGLAIT", "TENIET EN NASR", "TESMART", "TIXTER", "EL ACH");
        // Wilaya 35 - Boumerdès
        AddCommunes(communes, ref id, 35, "BOUMERDES", "DELLYS", "BORDJ MENAIEL", "KHEMIS EL KHECHNA", "NACIRIA", "BOUDOUAOU", "ISSER", "THENIA", "HAMMEDI", "SI MUSTAPHA", "TIDJELABINE", "CORSO", "OULED MOUSSA", "LARBATACHE", "AFIR", "AMMAL", "BEN CHOUD", "BENI AMRANE", "BOUDOUAOU EL BAHRI", "BOUZEGZA KEDDARA", "CHABET EL AMEUR", "DJINET", "EL KHARROUBA", "KEDDARA", "LEGHATA", "OULED HEDADJ", "SIDI DAOUD", "SOUK EL HAD", "TAOURGA", "ZEMMOURI", "TIMEZRIT", "OULED AISSA");
        // Wilaya 36 - El Tarf
        AddCommunes(communes, ref id, 36, "EL TARF", "EL KALA", "BEN M'HIDI", "BESBES", "DREAN", "BOUTELDJA", "AIN EL ASSEL", "LAC DES OISEAUX", "ZERIZER", "CHIHANI", "CHEFIA", "CHEBAITA MOKHTAR", "ASFOUR", "BERRIHANE", "BOUGOUS", "BOUHADJAR", "EL AIOUN", "HAMMAM BENI SALAH", "OUED ZITOUN", "RAML SOUK SOUAREKH", "ZITOUNA", "AIN KERMA", "ECHATT", "SOUAREKH", "SOUK EL HAAD", "RAML SOUK");
        // Wilaya 37 - Tindouf
        AddCommunes(communes, ref id, 37, "TINDOUF", "OUM EL ASSEL");
        // Wilaya 38 - Tissemsilt
        AddCommunes(communes, ref id, 38, "TISSEMSILT", "THENIET EL HAD", "BORDJ BOU NAAMA", "LARDJEM", "KHEMISTI", "LAZHARIA", "AMMARI", "OULED BESSEM", "BENI CHAIB", "SIDI LANTRI", "BORDJ EL EMIR ABDELKADER", "LAYOUNE", "MAASSEM", "MELAAB", "SIDI ABED", "SIDI BOUTOUCHENT", "TAMALAHT", "BENI LAHCENE", "BOUCAID", "LARBAA", "SIDI SLIMANE", "YOUSSOUFIA");
        // Wilaya 39 - El Oued
        AddCommunes(communes, ref id, 39, "EL OUED", "GUEMAR", "ROBBAH", "BAYADHA", "OUED EL ALENDA", "DEBILA", "HASSANI ABDELKRIM", "TALEB LARBI", "KOUININE", "OUERMAS", "EL BAYADHA", "BEN GUECHA", "EL DEBILA", "DOUAR EL MA", "EL OGLA", "EL OGLA", "EL HAMRAIA", "HASSI KHELIFA", "EL MAGRANE", "MIH OUENSA", "EL REGUIBA", "EL ROBBAH", "SIDI AOUN", "TAGHZOUT", "EL TRIFAOUI", "EL NAKHLA");
        // Wilaya 40 - Khenchela
        AddCommunes(communes, ref id, 40, "KHENCHELA", "KAIS", "AIN TOUILA", "BABAR", "CHECHAR", "EL HAMMA", "BOUHMAMA", "OULED RECHACHE", "EL MAHMAL", "TAMZA", "YABOUS", "BAGHAI", "CHELIA", "DJELLAL", "EL OUELDJA", "ENSIGHA", "KHIRANE", "M'SARA", "M'TOUSSA", "REMILA", "TAOUZIANAT");
        // Wilaya 41 - Souk Ahras
        AddCommunes(communes, ref id, 41, "SOUK AHRAS", "SEDRATA", "MECHROHA", "AIN SOLTANE", "AIN ZANA", "HADDADA", "M'DAOUROUCHE", "TAOURA", "OUM EL ADHAIM", "OULED DRISS", "ZAAROURIA", "BIR BOUHOUCHE", "DREA", "HANANCHA", "KHEDARA", "KHEMISSA", "MERAHNA", "OUED KEBERIT", "OUILLEN", "OULED MOUMENE", "RAGOUBA", "SAFEL EL OUIDEN", "SIDI FREDJ", "TERRAGUELT", "TIFFECH");
        // Wilaya 42 - Tipaza
        AddCommunes(communes, ref id, 42, "TIPAZA", "HADJOUT", "KOLEA", "CHERCHELL", "BOU ISMAIL", "GOURAYA", "FOUKA", "DAMOUS", "SIDI AMAR", "NADOR", "AHMER EL AIN", "AIN TAGOURAIT", "MENACEUR", "ATTATBA", "BOU HAROUN", "AGHBAL", "BENI MILLEUK", "BOURKIKA", "CHAIBA", "DOUAOUDA", "HADJERAT ENNOUS", "LARHAT", "MESSELMOUN", "MEURAD", "SIDI GHILES", "SIDI RACHED", "SIDI SEMIANE", "KHEMISTI");
        // Wilaya 43 - Mila
        AddCommunes(communes, ref id, 43, "MILA", "FERDJIOUA", "CHELGHOUM LAID", "OUED ATHMENIA", "GRAREM GOUGA", "TASSADANE HADDADA", "ROUACHED", "AIN BEIDA HARRICHE", "SIDI MERUANE", "TELERGHMA", "ZEGHAIA", "BENYAHIA ABDERRAHMANE", "AHMED RACHEDI", "AIN MELLOUK", "AIN TINE", "AMIRA ARRAS", "BOUHATEM", "CHIGARA", "DERRAHI BOUSSELAH", "EL MECHIRA", "ELAYADI BARBES", "HAMALA", "MINAR ZARZA", "OUED ENDJA", "OUED SEGUEN", "OULED KHALOUF", "SIDI KHELIFA", "SIDI MEROUANE", "TADJENANET", "TERRAI BAINEM", "TESSALA LEMATAI", "TIBERGUENT", "YAHIA BENIGUECHA");
        // Wilaya 44 - Aïn Defla
        AddCommunes(communes, ref id, 44, "AIN DEFLA", "MILIANA", "KHEMIS MILIANA", "EL ATTAF", "DJELIDA", "HAMMAM RIGHA", "AIN LECHIAKH", "BOUMEDFAA", "EL ABADIA", "BORDJ EL EMIR KHALED", "ROUINA", "BIR OULD KHELIFA", "LEMKHATRIA", "AIN BOUYAHIA", "AIN TORKI", "ARIB", "BARBOUCHE", "BATHIA", "BELAAS", "BEN ALLEL", "BOURACHED", "DJEMAA OULED CHIKH", "DJENDEL", "EL AMRA", "EL HASSANIA", "EL MAIN", "HOCEINIA", "OUED CHEURFA", "OUED DJEMAA", "SIDI LAKHDAR", "TACHETA ZOUGAGHA", "TARIK IBN ZIAD", "TIBERKANINE", "ZEDDINE", "AIN BENIAN", "AIN SOLTANE");
        // Wilaya 45 - Naâma
        AddCommunes(communes, ref id, 45, "NAAMA", "MECHERIA", "AIN SEFRA", "TIOUT", "SFISSIFA", "ASSELA", "DJENIANE BOURZEG", "MOGHRAR", "AIN BEN KHELIL", "EL BIOD", "KASDIR", "MAKMAN BEN AMER");
        // Wilaya 46 - Aïn Témouchent
        AddCommunes(communes, ref id, 46, "AIN TEMOUCHENT", "EL MALAH", "BENI SAF", "HAMMAM BOUHADJAR", "EL AMRIA", "AIN KIHAL", "AIN TOLBA", "OULHACA EL GHERABA", "CHENTOUF", "SIDI BEN ADDA", "AGHLAL", "AIN EL ARBAA", "AOUBELLIL", "BOU ZEDJAR", "CHAABET EL HAM", "EL EMIR ABDELKADER", "EL MESSAID", "HASSI EL GHELLA", "OUED BERKECHE", "OUED SABAH", "OULED BOUDJEMAA", "OULED KIHAL", "SIDI BOUMEDIENE", "SIDI SAFI", "TAMZOURA", "TERGA", "HASSASNA", "SIDI OURIACH");
        // Wilaya 47 - Ghardaïa
        AddCommunes(communes, ref id, 47, "GHARDAIA", "METLILI", "BERRIANE", "EL GUERRARA", "EL ATTEUF", "DHAYET BENDHAHOUA", "ZELFANA", "SEBSEB", "BOUNOURA", "MANSOURA");
        // Wilaya 48 - Relizane
        AddCommunes(communes, ref id, 48, "RELIZANE", "OUED RHIOU", "MAZOUNA", "AMMI MOUSSA", "YELLEL", "ZEMMOURA", "AIN TAREK", "MENDES", "DJIDIOUIA", "EL MATMAR", "SIDI M'HAMED BEN ALI", "RAMKA", "EL HASSI", "AIN RAHMA", "BELAASSEL BOUZEGZA", "BENDAOUD", "BENI DERGOUN", "BENI ZENTIS", "DAR BEN ABDELLAH", "EL GUETTAR", "EL HAMADNA", "EL OULDJA", "HAD ECHKALLA", "HAMRI", "KALAA", "LAHLEF", "MEDIOUNA", "MERDJA SIDI ABED", "OUARIZANE", "OUED ESSALEM", "OULED AICHE", "OUED EL DJEMAA", "OULED SIDI MIHOUB", "SIDI KHETTAB", "SIDI LAZREG", "SIDI M'HAMED BEN AOUDA", "SIDI SAADA", "SOUK EL HAAD");
        // Wilaya 49 - Timimoun
        AddCommunes(communes, ref id, 49, "TIMIMOUN", "OULED SAID", "AOUGROUT", "DELDOUL", "TINERKOUK", "CHAROUINE", "TALMINE", "KSAR KADDOUR", "METARFA", "OULED AISSA");
        // Wilaya 50 - Bordj Badji Mokhtar
        AddCommunes(communes, ref id, 50, "BORDJ BADJI MOKHTAR", "TIMIAOUINE");
        // Wilaya 51 - Ouled Djellal
        AddCommunes(communes, ref id, 51, "OULED DJELLAL", "SIDI KHALED", "DOUCEN", "ECH CHAIBA", "RAS EL MIAAD", "BESBES");
        // Wilaya 52 - Béni Abbès
        AddCommunes(communes, ref id, 52, "BENI ABBES", "BENI IKHLEF", "EL OUATA", "IGLI", "KERZAZ", "KSABI", "TAMTERT", "TIMOUDI", "TABALBALA");
        // Wilaya 53 - In Salah
        AddCommunes(communes, ref id, 53, "AIN SALAH", "FOGGARET EZZOUA", "AIN GHAR");
        // Wilaya 54 - In Guezzam
        AddCommunes(communes, ref id, 54, "IN GUEZZAM", "TINZAOUATINE");
        // Wilaya 55 - Touggourt
        AddCommunes(communes, ref id, 55, "TOUGGOURT", "BENACEUR", "BALIDAT AMEUR", "EL ALLIA", "EL HADJIRA", "MEGARINE", "M'NAGUER", "NEZLA", "SIDI SLIMANE", "TAIBET", "TAMACINE", "TEBESBEST", "ZAOUIA EL ABIDIA");
        // Wilaya 56 - Djanet
        AddCommunes(communes, ref id, 56, "DJANET", "BORDJ EL HAOUASSE");
        // Wilaya 57 - El M'Ghair
        AddCommunes(communes, ref id, 57, "EL M'GHAIR", "DJAMAA", "EL MRARA", "OUM TOUYOUR", "SIDI AMRANE", "STILL", "TENDLA", "SIDI KHELLIL");
        // Wilaya 58 - El Meniaa
        AddCommunes(communes, ref id, 58, "EL MENIAA", "HASSI FEHAL", "HASSI GARA");

        return communes;
    }

    private static void AddCommunes(List<Commune> communes, ref int id, int wilayaId, params string[] names)
    {
        foreach (var name in names)
        {
            communes.Add(new Commune { Name = name, WilayaId = wilayaId });
            id++;
        }
    }
}
