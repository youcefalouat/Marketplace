using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using MarketplaceApi.DTOs;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PublicController : ControllerBase
{
    private readonly IMemoryCache _cache;
    private static readonly DateTime _termsUpdatedAt = new DateTime(2026, 6, 9, 0, 0, 0, DateTimeKind.Utc);

    public PublicController(IMemoryCache cache) => _cache = cache;

    // ─── GET /api/public/terms ───

    [HttpGet("terms")]
    public IActionResult GetTerms()
    {
        if (_cache.TryGetValue("legal_terms", out LegalContentDto? cached))
            return Ok(cached);

        var content = new LegalContentDto
        {
            TitleFr = "Conditions d'utilisation",
            TitleAr = "شروط الاستخدام",
            UpdatedAt = _termsUpdatedAt,
            ContentFr = """
                ## 1. Objet

                L'application met à disposition une plateforme permettant aux utilisateurs de publier des annonces, communiquer entre eux et effectuer des réservations lorsque cette fonctionnalité est disponible.

                ## 2. Inscription

                L'inscription est réservée aux personnes fournissant des informations exactes et à jour. L'utilisateur est responsable de la confidentialité de son compte.

                ## 3. Contenu publié

                L'utilisateur s'engage à ne publier aucun contenu :

                - illégal ;
                - trompeur ;
                - diffamatoire ;
                - portant atteinte aux droits d'autrui ;
                - contenant des spams ou des contenus frauduleux.

                L'éditeur peut supprimer tout contenu ne respectant pas ces règles.

                ## 4. Transactions

                La plateforme facilite la mise en relation entre utilisateurs mais n'est pas partie aux transactions réalisées entre eux.

                Chaque utilisateur reste responsable de ses échanges, ventes, achats et réservations.

                ## 5. Messagerie

                Les utilisateurs s'engagent à utiliser la messagerie de manière respectueuse et à ne pas envoyer de contenus abusifs, frauduleux ou publicitaires non sollicités.

                ## 6. Réservation

                Lorsqu'une annonce propose une réservation, celle-ci respecte l'ordre chronologique des demandes mais ne constitue pas une garantie définitive de vente.

                ## 7. Suspension du compte

                L'éditeur peut suspendre ou supprimer un compte en cas de fraude, de non-respect des présentes conditions ou d'utilisation abusive de la plateforme.

                ## 8. Limitation de responsabilité

                L'application fournit un service d'intermédiation et ne garantit ni la qualité des biens proposés, ni la bonne exécution des transactions entre utilisateurs.
                """,
            ContentAr = """
                ## 1. الهدف

                توفر المنصة إمكانية نشر الإعلانات والتواصل بين المستخدمين وإجراء الحجوزات عند توفر هذه الميزة.

                ## 2. التسجيل

                يلتزم المستخدم بتقديم معلومات صحيحة وتحديثها والمحافظة على سرية حسابه.

                ## 3. المحتوى

                يمنع نشر أي محتوى غير قانوني أو مضلل أو مسيء أو ينتهك حقوق الآخرين أو يتضمن احتيالاً أو رسائل مزعجة.

                ## 4. المعاملات

                تعمل المنصة كوسيط بين المستخدمين ولا تعتبر طرفاً في عمليات البيع أو الشراء أو التبادل.

                ## 5. الرسائل

                يجب استخدام نظام المراسلة بطريقة محترمة وعدم إرسال رسائل احتيالية أو إعلانات غير مرغوب فيها.

                ## 6. الحجوزات

                ترتيب الحجوزات يعتمد على أولوية الطلب ولا يشكل التزاماً نهائياً بإتمام عملية البيع.

                ## 7. إيقاف الحساب

                يحق لإدارة المنصة تعليق أو حذف أي حساب يخالف هذه الشروط أو يستخدم التطبيق بطريقة غير مشروعة.

                ## 8. المسؤولية

                لا تتحمل المنصة مسؤولية جودة المنتجات أو تنفيذ الاتفاقيات بين المستخدمين.
                """
        };

        _cache.Set("legal_terms", content, TimeSpan.FromHours(24));
        return Ok(content);
    }

    // ─── GET /api/public/privacy ───

    [HttpGet("privacy")]
    public IActionResult GetPrivacy()
    {
        if (_cache.TryGetValue("legal_privacy", out LegalContentDto? cached))
            return Ok(cached);

        var content = new LegalContentDto
        {
            TitleFr = "Politique de confidentialité",
            TitleAr = "سياسة الخصوصية",
            UpdatedAt = _termsUpdatedAt,
            ContentFr = """
                ## 1. Collecte des données

                Nous collectons les informations que vous nous fournissez lors de l'inscription : nom, email, numéro de téléphone, wilaya et commune. Nous collectons également des données d'utilisation de l'application de manière anonyme.

                ## 2. Utilisation des données

                Vos données sont utilisées pour :

                - Gérer votre compte et vos annonces ;
                - Vous envoyer des notifications relatives à vos annonces et messages ;
                - Améliorer nos services.

                ## 3. Partage des données

                Nous ne vendons pas vos données personnelles. Vos coordonnées ne sont partagées qu'avec les utilisateurs avec qui vous choisissez de communiquer via la plateforme.

                ## 4. Sécurité

                Nous prenons des mesures raisonnables pour protéger vos données contre tout accès non autorisé, notamment le chiffrement des mots de passe et des communications.

                ## 5. Conservation des données

                Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression de votre compte à tout moment en contactant le support.

                ## 6. Vos droits

                Vous disposez d'un droit d'accès, de rectification et de suppression de vos données personnelles. Pour exercer ces droits, contactez-nous.

                ## 7. Contact

                Pour toute question relative à cette politique, vous pouvez nous contacter via l'application.
                """,
            ContentAr = """
                ## 1. جمع البيانات

                نجمع المعلومات التي تقدمها عند التسجيل: الاسم، البريد الإلكتروني، رقم الهاتف، الولاية والبلدية. كما نجمع بيانات استخدام التطبيق بشكل مجهول.

                ## 2. استخدام البيانات

                تُستخدم بياناتك من أجل:

                - إدارة حسابك وإعلاناتك؛
                - إرسال إشعارات تتعلق بإعلاناتك ورسائلك؛
                - تحسين خدماتنا.

                ## 3. مشاركة البيانات

                لا نبيع بياناتك الشخصية. لا تُشارك معلومات الاتصال الخاصة بك إلا مع المستخدمين الذين تختار التواصل معهم عبر المنصة.

                ## 4. الأمان

                نتخذ تدابير معقولة لحماية بياناتك من الوصول غير المصرح به، بما في ذلك تشفير كلمات المرور والاتصالات.

                ## 5. الاحتفاظ بالبيانات

                يتم الاحتفاظ ببياناتك طالما حسابك نشط. يمكنك طلب حذف حسابك في أي وقت عن طريق التواصل مع الدعم.

                ## 6. حقوقك

                لديك حق الوصول إلى بياناتك الشخصية وتصحيحها وحذفها. للاستفادة من هذه الحقوق، تواصل معنا.

                ## 7. التواصل

                لأي استفسار يتعلق بهذه السياسة، يمكنك التواصل معنا عبر التطبيق.
                """
        };

        _cache.Set("legal_privacy", content, TimeSpan.FromHours(24));
        return Ok(content);
    }
}
