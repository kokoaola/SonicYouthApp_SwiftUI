//
//  ContentView.swift
//  iTunesAPI
//
//  Created by koala panda on 2023/08/27.
//
//
import SwiftUI

struct ContentView: View {
    @State private var results = [Result]()
    let dateFormatter = ISO8601DateFormatter()
    
    var body: some View {
        NavigationStack{
            //アルバムの画像とアルバム名・リリース年を表示
            List(results, id: \.collectionId) { item in
                
                
                NavigationLink {
                    DetailView(item: item)
                } label: {
                    
                    HStack{
                        
                        AsyncImage(url: URL(string: item.artworkUrl100)){ phase in
                            switch phase {
                            case .empty:
                                // 画像のダウンロード前はローディングスピナーを表示
                                ProgressView().frame(width: 100, height: 100)
                            case .success(let image):
                                // 画像のダウンロード成功時はリサイズした画像を表示
                                image.resizable().aspectRatio(contentMode: .fill).frame(width: 100, height: 100).clipped()
                                
                            case .failure:
                                // 画像のダウンロード失敗時はエラーアイコンを表示
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .frame(width: 100, height: 100)
                            @unknown default:
                                Image(systemName: "xmark.circle")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            // アルバム名を表示
                            Text(item.collectionName)
                                .font(.title3).bold()
                            // リリース年を表示
                            Text(dateFormatter.date(from: item.releaseDate) ?? Date(), format: .dateTime.year())
                                .font(.callout)
                                .padding(.top, 1)
                        }
                    }
                }
            }
            .task {
                await loadData()
            }
            .navigationTitle("Sonic Youth")
        }
    }
    
    //APIを読みこむメソッド
    func loadData() async {
        guard let url = URL(string: "https://itunes.apple.com/search?term=sonic+youth&entity=album&limit=200") else {
            print("Invalid URL")
            return
        }
        do {
            //タプルで帰ってくるのでURLはDataに入れて、メタデータは捨てる
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
                results = decodedResponse.results
            }
        } catch {
            print("Invalid data")
        }
        
        //リリース順に並び替え
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"  // 例えば、ISO8601形式の場合
        
        results.sort {
            guard let date1 = dateFormatter.date(from: $0.releaseDate),
                  let date2 = dateFormatter.date(from: $1.releaseDate) else {
                // もし変換に失敗したら、その要素を後ろに
                return false
            }
            // 昇順にソート
            return date1 < date2
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





///Modelたち
struct Result: Codable {
    // entity=albumのときはcollectionId
    // entity=songのときはtrackId
    var collectionId: Int
    var artworkUrl100: String
    var collectionName: String
    var releaseDate: String
    var trackCount: Int
}

class Response: Codable {
    var results: [Result]
}


/*
 trackId: Int - 曲やアルバムのユニークなID
 trackName: String - 曲の名前
 collectionId: Int - アルバムのユニークなID
 collectionName: String - アルバムの名前
 artistId: Int - アーティストのユニークなID
 artistName: String - アーティストの名前
 artworkUrl30, artworkUrl60, artworkUrl100: String - アートワークのURL（異なるサイズが3つ）
 collectionPrice: Double - アルバムの価格
 trackPrice: Double - 曲の価格
 releaseDate: String  - リリース日
 collectionCensoredName: String - センサーされたアルバム名
 trackCensoredName: String - センサーされた曲名
 primaryGenreName: String - 主要なジャンル名
 trackCount: Int - アルバムに含まれる曲の数
 trackNumber: Int - アルバム内の曲の番号
 country: String - 国名
 currency: String - 価格の通貨単位（例：USD、JPYなど）
 previewUrl: String - 曲のプレビューURL
 */
