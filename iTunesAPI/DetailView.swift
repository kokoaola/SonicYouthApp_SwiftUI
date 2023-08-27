//
//  DetailView.swift
//  iTunesAPI
//
//  Created by koala panda on 2023/08/27.
//

import SwiftUI

struct DetailView: View {
    var item: Result
    @State private var tracks = [Track]()
    let dateFormatter = ISO8601DateFormatter()
    
    var body: some View {
        NavigationStack{
            List{
                //画像を表示
                HStack{
                    Spacer()
                    AsyncImage(url: URL(string: item.artworkUrl100)){ phase in
                        switch phase {
                        case .empty:
                            // 画像のダウンロード前はローディングスピナーを表示
                            ProgressView().frame(width: 100, height: 100)
                        case .success(let image):
                            // 画像のダウンロード成功時はリサイズした画像を表示
                            image.resizable().aspectRatio(contentMode: .fill).frame(width: 200, height: 200).clipped()
                            
                        case .failure:
                            // 画像のダウンロード失敗時はエラーアイコンを表示
                            Image(systemName: "xmark.circle")
                                .frame(width: 100, height: 100)
                        @unknown default:
                            Image(systemName: "xmark.circle")
                        }
                    }
                    Spacer()
                }
                
                //曲名を表示
                ForEach(tracks, id: \.trackName) { track in
                    
                    Text("\(track.trackNumber ?? 0). \(track.trackName ?? "")")
                }
            }
            
            .navigationTitle("\(item.collectionName) ( \(dateFormatter.date(from: item.releaseDate) ?? Date(), format: .dateTime.year()) )")
        }
        
        .task {
            await loadData()
        }
    }
    
    //曲名をロードする
    func loadData() async {
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(item.collectionId)&entity=song") else {
            print("Invalid URL")
            return
        }
        
        do {
            //タプルで帰ってくるのでURLはDataに入れて、メタデータは捨てる
            let (data, _) = try await URLSession.shared.data(from: url)
            
            do {
                let decodedResponse = try JSONDecoder().decode(TrackResponse.self, from: data)
                // 最初の結果はアルバムの情報なので除外
                tracks = Array(decodedResponse.results.dropFirst())
            } catch {
                //エラーメッセージ "The data couldn’t be read because it is missing." は、JSONの構造とCodableのモデルが一致していない
                print("Decoding failed: \(error.localizedDescription)")
            }
        } catch {
            print("Invalid data")
        }

    }
}


///Modelたち
struct Track: Codable {
    var trackId: Int?
    var trackName: String?
    var trackNumber: Int?
}

class TrackResponse: Codable {
    var results: [Track]
}


struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(item: Result(collectionId: 123, artworkUrl100: "", collectionName: "", releaseDate: "", trackCount: 1 ))
    }
}
