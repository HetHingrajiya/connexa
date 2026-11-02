namespace Connexa.Api.Entities;

public enum ProfileTypeEnum
{
    BusinessCompany = 1,
    EmployeeJobSeeker = 2,
    ServiceEngineer = 3,
    TraderSupplier = 4,
    ContractorJobWorker = 5
}

public class Member
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string CountryCode { get; set; } = "+91";
    public string PhoneNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public ProfileTypeEnum PrimaryProfileType { get; set; }
    public string VerifiedMethod { get; set; } = string.Empty; // "Email" or "WhatsApp"
    public string VerifiedDestination { get; set; } = string.Empty;
    public string Role { get; set; } = "Member"; // Strictly "Member" for public registration
    public bool IsActive { get; set; } = true;
    public DateTime? DeactivatedAtUtc { get; set; }
    public string? DeactivationReason { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // Security & Credential Setup
    public string? PasswordHash { get; set; }
    public string? PasswordSalt { get; set; }
    public string? CredentialSetupToken { get; set; }
    public DateTime? CredentialSetupTokenExpiresAtUtc { get; set; }
    public int FailedLoginAttempts { get; set; } = 0;
    public DateTime? LockoutEndUtc { get; set; }

    // 1-to-1 Profile navigations
    public BusinessProfile? BusinessProfile { get; set; }
    public EmployeeProfile? EmployeeProfile { get; set; }
    public ServiceEngineerProfile? ServiceEngineerProfile { get; set; }
    public TraderProfile? TraderProfile { get; set; }
    public ContractorProfile? ContractorProfile { get; set; }

    // Refresh Tokens navigation
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

    // Member Connections navigation
    public ICollection<MemberConnection> SentConnections { get; set; } = new List<MemberConnection>();
    public ICollection<MemberConnection> ReceivedConnections { get; set; } = new List<MemberConnection>();

    // Products & Analytics navigation
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<ProfileView> ProfileViews { get; set; } = new List<ProfileView>();
    public ICollection<ProductInquiry> SentInquiries { get; set; } = new List<ProductInquiry>();
    public ICollection<ProductInquiry> ReceivedInquiries { get; set; } = new List<ProductInquiry>();

    // Notifications navigation
    public ICollection<Notification> ReceivedNotifications { get; set; } = new List<Notification>();
    public ICollection<Notification> TriggeredNotifications { get; set; } = new List<Notification>();
    public ICollection<DeviceToken> DeviceTokens { get; set; } = new List<DeviceToken>();

    // Business Verification navigation
    public ICollection<BusinessVerificationRequest> VerificationRequests { get; set; } = new List<BusinessVerificationRequest>();
    public ICollection<BusinessVerificationRequest> ReviewedVerificationRequests { get; set; } = new List<BusinessVerificationRequest>();

    // B2B RFQ & Quotations navigation
    public ICollection<Rfq> SentRfqs { get; set; } = new List<Rfq>();
    public ICollection<Rfq> ReceivedRfqs { get; set; } = new List<Rfq>();
    public ICollection<Quotation> SubmittedQuotations { get; set; } = new List<Quotation>();
    public ICollection<Quotation> ReceivedQuotations { get; set; } = new List<Quotation>();

    // B2B Orders navigation
    public ICollection<Order> SentOrders { get; set; } = new List<Order>();
    public ICollection<Order> ReceivedOrders { get; set; } = new List<Order>();

    // Industrial Job Work navigation
    public ICollection<JobWorkRequirement> PostedJobWorkRequirements { get; set; } = new List<JobWorkRequirement>();
    public ICollection<JobWorkQuotation> SubmittedJobWorkQuotations { get; set; } = new List<JobWorkQuotation>();
    public ICollection<JobWorkOrder> PlacedJobWorkOrders { get; set; } = new List<JobWorkOrder>();
    public ICollection<JobWorkOrder> ReceivedJobWorkOrders { get; set; } = new List<JobWorkOrder>();

    // Security & Account Deletion Requests navigation
    public ICollection<AccountDeletionRequest> DeletionRequests { get; set; } = new List<AccountDeletionRequest>();

    // B2B Services Marketplace navigation
    public ICollection<BusinessService> PublishedServices { get; set; } = new List<BusinessService>();
    public ICollection<ServiceInquiry> SentServiceInquiries { get; set; } = new List<ServiceInquiry>();
    public ICollection<ServiceInquiry> ReceivedServiceInquiries { get; set; } = new List<ServiceInquiry>();

    // Job Recruitment Marketplace navigation
    public ICollection<JobOpening> PostedJobOpenings { get; set; } = new List<JobOpening>();
    public ICollection<JobApplication> SubmittedJobApplications { get; set; } = new List<JobApplication>();

    // Business Posts & Feed navigation
    public ICollection<BusinessPost> BusinessPosts { get; set; } = new List<BusinessPost>();
    public ICollection<BusinessPostLike> PostLikes { get; set; } = new List<BusinessPostLike>();
    public ICollection<BusinessPostComment> PostComments { get; set; } = new List<BusinessPostComment>();
    public ICollection<BusinessPostReport> PostReports { get; set; } = new List<BusinessPostReport>();
}

