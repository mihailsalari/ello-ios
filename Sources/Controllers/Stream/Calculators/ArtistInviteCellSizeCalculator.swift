////
///  ArtistInviteCellSizeCalculator.swift
//

class ArtistInviteCellSizeCalculator: NSObject {
    let webView: UIWebView
    fileprivate typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, completion: Block)
    fileprivate var cellJobs: [CellJob] = []
    fileprivate var cellItems: [StreamCellItem] = []
    fileprivate var completion: Block = {}

    init(webView: UIWebView = UIWebView()) {
        self.webView = webView
        super.init()
        self.webView.delegate = self
    }

// MARK: Public

    func processCells(_ cellItems: [StreamCellItem], withWidth width: CGFloat, completion: @escaping Block) {
        guard cellItems.count > 0 else {
            completion()
            return
        }

        let job: CellJob = (cellItems: cellItems, width: width, completion: completion)
        cellJobs.append(job)
        if cellJobs.count == 1 {
            processJob(job)
        }
    }

// MARK: Private

    fileprivate func processJob(_ job: CellJob) {
        self.completion = {
            if self.cellJobs.count > 0 {
                self.cellJobs.remove(at: 0)
            }
            job.completion()
            if let nextJob = self.cellJobs.safeValue(0) {
                self.processJob(nextJob)
            }
        }

        cellItems = job.cellItems
        var webWidth = job.width
        webWidth -= ArtistInviteBubbleCell.Size.bubbleMargins.left + ArtistInviteBubbleCell.Size.bubbleMargins.right
        webWidth -= ArtistInviteBubbleCell.Size.descriptionMargins.left + ArtistInviteBubbleCell.Size.descriptionMargins.right
        webView.frame = webView.frame.with(width: webWidth)

        loadNext()
    }

    fileprivate func loadNext() {
        guard !self.cellItems.isEmpty else {
            completion()
            return
        }

        let cellItem = cellItems[0]
        guard
            let artistInvite = cellItem.jsonable as? ArtistInvite
        else {
            assignHeight(nil)
            return
        }

        switch cellItem.type {
        case .artistInviteBubble:
            calculateBubbleHeight(cellItem, artistInvite)
        case .artistInviteControls:
            calculateControlsHeight(cellItem, artistInvite)
        case .artistInviteGuide:
            calculateGuideHeight(cellItem, artistInvite)
        default:
            assignHeight(nil)
        }
    }

    fileprivate func calculateBubbleHeight(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        let text = artistInvite.shortDescription
        let html = StreamTextCellHTML.artistInviteHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    fileprivate func calculateControlsHeight(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        let text = artistInvite.longDescription
        let html = StreamTextCellHTML.postHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    fileprivate func calculateGuideHeight(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        guard let guide = cellItem.type.data as? ArtistInvite.Guide else {
            assignHeight(nil)
            return
        }
        let text = guide.html
        let html = StreamTextCellHTML.artistInviteGuideHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    fileprivate func assignHeight(_ height: CGFloat?) {
        let cellItem = cellItems.remove(at: 0)
        defer { loadNext() }
        guard let height = height else { return }

        let calculatedHeight: CGFloat?
        switch cellItem.type {
        case .artistInviteBubble:
            calculatedHeight = assignBubbleHeight(cellItem, height)
        case .artistInviteControls:
            calculatedHeight = assignControlsHeight(cellItem, height)
        case .artistInviteGuide:
            calculatedHeight = assignGuideHeight(cellItem, height)
        default:
            calculatedHeight = nil
        }

        if let height = calculatedHeight {
            cellItem.calculatedCellHeights.webContent = height
            cellItem.calculatedCellHeights.oneColumn = height
            cellItem.calculatedCellHeights.multiColumn = height
        }
    }

    fileprivate func assignBubbleHeight(_ cellItem: StreamCellItem, _ height: CGFloat) -> CGFloat {
        var totalHeight = height
        totalHeight += ArtistInviteBubbleCell.Size.bubbleMargins.top
        totalHeight += ArtistInviteBubbleCell.Size.headerImageHeight
        totalHeight += ArtistInviteBubbleCell.Size.infoTotalHeight
        totalHeight += (height > 0 ? ArtistInviteBubbleCell.Size.descriptionMargins.bottom : 0)
        totalHeight += ArtistInviteBubbleCell.Size.bubbleMargins.bottom
        return totalHeight
    }

    fileprivate func assignControlsHeight(_ cellItem: StreamCellItem, _ height: CGFloat) -> CGFloat {
        return ArtistInviteControlsCell.Size.controlsHeight + height
    }

    fileprivate func assignGuideHeight(_ cellItem: StreamCellItem, _ height: CGFloat) -> CGFloat {
        return ArtistInviteGuideCell.Size.otherHeights + height
    }
}

extension ArtistInviteCellSizeCalculator: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let textHeight = webView.windowContentSize()?.height
        assignHeight(textHeight ?? 0)
    }
}