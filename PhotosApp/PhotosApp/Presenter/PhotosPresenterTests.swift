import XCTest
@testable import PhotosApp

class PhotosPresenterTests: XCTestCase {
    func testExample() {
        let expectedResult = [ImageModel(albumId: 1, id: 1, title: "dummy", url: "url", thumbnailUrl: "thumbnail")]
        
        let mock = PhotosInteractorInteraceProtocolMock()
        mock.fetchImagesResult = .success(imageModels: expectedResult)
        
        let presenter = PhotosPresenter(photosInteractor: mock)
        presenter.startFetchingImages()
        XCTAssertEqual(presenter.numberOfRows(), expectedResult.count)
        
    }

}

private class PhotosInteractorInteraceProtocolMock: PhotosInteractorInteraceProtocol {
    var delegate : PhotosInteractorDelegateProtocol?
    var fetchImagesResult: PhotosApp.ResultType!
    
    func fetchImages() {
        delegate?.didFetchPhotos(result: fetchImagesResult)
    }
    
}
