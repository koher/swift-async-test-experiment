# AsyncTestExperiment

このリポジトリのコードは、 Swift Concurrency を使った非同期メソッドのテストのサンプルです。ここではコードの内容を簡単に説明します。

`FooViewModel` の `load` メソッドを呼び出すと、内部で `FooService` を使って非同期にデータを取得します。データの取得中は `isLoading` が `true` になり、 View はそれを購読してローディングインジケータを表示します。処理が完了すると `isLoading` は `false` に戻り、ローディングインジケータは非表示となります（ただし、本リポジトリには View の部分は含まれていません）。

このとき、 `FooViewModel` の `load` メソッドにおいて、 `isLoading` が処理中だけ `true` になることをテストしたいとします。一般的な非同期メソッドのテストであれば `await` して結果をテストすれば良いですが、 `load` メソッドを `await` すると処理が完了してしまい、処理中の状態をテストすることができません。このような場合は、次のようにして処理中の状態をテストできます。

1. まず、 `load` メソッドを `await` するのではなく、 `async let` を使って結果を待たず後続処理を実行できるようにします。
2. 次に、 `load` の処理が開始されると `isLoading` が `true` になっていることをテストします。
3. そして、（テストのために DI した） `FooService` に結果を返させます。
4. 最後に、 `async let` した `load` メソッドを `await` します。

```swift
async let result: Void = viewModel.load() // 1
...
XCTAssertTrue(viewModel.isLoading) // 2

FooService.fetchFooContinuation!.resume(returning: Foo(id: "abc", value: 42)) // 3
...
await result // 4
```

このようにすれば、 `load` の処理中の状態をテストできます。

## 注意点

しかし、実際には上記の 1 - 4 のステップだけでは十分ではありません。

`async let` を使った場合、 `load` メソッドは即座に実行されません（ `load` の最初の `await` まで同期的に実行されると良いですが、そのような挙動ではありません）。そのため、そのままでは 2 に到達したときには `isLoading` はまだ `false` のままです。そこで、 1 と 2 の間で少しの間、処理を待つ必要があります。

そんなときに便利なのが `Task.yield()` です。

```swift
await Task.yield()
```

これを一つ入れるだけで上手くいくこともあるのですが、 `Task.yield()` の呼び出し後の後続処理と `load` のどちらが先に実行されるかは不定です。そのため、 1 回の `Task.yield()` では不十分なことがあります。それどころか、何回呼び出しても確実な保証はありません。そこで、 `load` メソッドが実行されるまで `while` ループで `Task.yield()` を呼び出し続けて待つようにします。

`load` メソッドが実行されると内部で `FooService.fetchFoo(for:)` が呼び出されます。非同期処理のタイミングをコントロールするには、テスト用の `FooService` を DI する必要があります。このテスト用 `FooService` の `fetchFoo(for:)` メソッドが呼び出されると、結果を返すための continuation をセットするようにします。

```swift
enum FooService: FooServiceProtocol {
    // 結果を返すための continuation
    static var fetchFooContinuation: CheckedContinuation<Foo, Error>?

    static func fetchFoo(for id: Foo.ID) async throws -> Foo {
        // fetchFoo が呼ばれたら continuation をセット
        try await withCheckedThrowingContinuation { continuation in
            fetchFooContinuation = continuation
        }
    }
}
```

そうすると、 `load` が実行されたことは continuation が `nil` でなくなったことで判断できます。

```swift
async let result: Void = viewModel.load() // 1

// load が実行されるまで while ループで待つ
while FooService.fetchFooContinuation == nil {
    await Task.yield()
}

XCTAssertTrue(viewModel.isLoading) // 2
```

また、 continuation を `resume` したら、 `nil` に戻すのを忘れないようにしましょう。

```swift
FooService.fetchFooContinuation!.resume(returning: Foo(id: "abc", value: 42)) // 3
FooService.fetchFooContinuation = nil // continuation を nil に戻す
await result // 4
```

continuation を `nil` に戻すことで、誤って二度 `resume` してしまったり、次のテストの `while` ループを待たずに抜けてしまったりすることを防止できます。
