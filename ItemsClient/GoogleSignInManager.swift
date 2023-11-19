import Foundation
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth

struct GoogleUser {
    let idToken: String
    let accessToken: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let profileImageUrl: URL?
    
    var displayName: String? {
        fullName ?? firstName ?? lastName
    }
    
    init?(result: GIDSignInResult) {
        guard let idToken = result.user.idToken?.tokenString else {
            return nil
        }

        self.idToken = idToken
        self.accessToken = result.user.accessToken.tokenString
        self.email = result.user.profile?.email
        self.firstName = result.user.profile?.givenName
        self.lastName = result.user.profile?.familyName
        self.fullName = result.user.profile?.name
        
        let dimension = round(400 * UIScreen.main.scale)
        
        if result.user.profile?.hasImage == true {
            self.profileImageUrl = result.user.profile?.imageURL(withDimension: UInt(dimension))
        } else {
            self.profileImageUrl = nil
        }
    }
    
    init?(user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else {
            return nil
        }

        self.idToken = idToken
        self.accessToken = user.accessToken.tokenString
        self.email = user.profile?.email
        self.firstName =  user.profile?.givenName
        self.lastName =  user.profile?.familyName
        self.fullName = user.profile?.name
        
        let dimension = round(400 * UIScreen.main.scale)
        
        if user.profile?.hasImage == true {
            self.profileImageUrl = user.profile?.imageURL(withDimension: UInt(dimension))
        } else {
            self.profileImageUrl = nil
        }
    }
}

final class GoogleSignInManager: ObservableObject {
    @Published var isSingedIn = false
    @Published var currentUser: GoogleUser?
    
    init(GIDClientID: String) {
        let config = GIDConfiguration(clientID: GIDClientID)
        GIDSignIn.sharedInstance.configuration = config
        tryRestorePreviousSignIn()
    }
    
    func tryRestorePreviousSignIn() {
        Task {
            do {
                if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                    try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                    guard let user = GIDSignIn.sharedInstance.currentUser else {
                        return
                    }

                    await MainActor.run { [weak self] in
                        self?.isSingedIn = true
                        self?.currentUser = GoogleUser(user: user)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    @MainActor
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSingedIn = false
        currentUser = nil
    }
    
    @MainActor
    func signIn(viewController: UIViewController? = nil) async throws {
        if GIDSignIn.sharedInstance.currentUser != nil {
          //  signOut()
            return
        }
        
        guard let topViewController = viewController ?? UIApplication.topViewController() else {
            throw GoogleSignInError.noViewController
        }
        
        do {
            let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)
            
            guard let result = GoogleUser(result: gidSignInResult) else {
                throw GoogleSignInError.badResponse
            }
            
            await MainActor.run { [weak self] in
                self?.isSingedIn = true
                self?.currentUser = result
            }
            
        } catch {
            // Handle sign-in error
            print(error)
            throw error
        }
    }
    
    private enum GoogleSignInError: LocalizedError {
        case noViewController
        case badResponse
    }
}


