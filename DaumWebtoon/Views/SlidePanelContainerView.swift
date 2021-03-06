//
//  SlidePanelContainerView.swift
//  DaumWebtoon
//
//  Created by Tak on 12/02/2019.
//  Copyright © 2019 Gaon Kim. All rights reserved.
//

import UIKit

protocol DetailEpisodeDelegate: class {
    func touchedEpisode(with episode: Episode)
}

class SlidePanelContainerView: UIView {
    private enum ButtonCategory {
        case recent
        case favorite
    }
    
    private var firstView = UIView()
    private var secondView = UITableView()
    private var recentButton = UIButton()
    private var favoriteButton = UIButton()
    
    private let dbService = DatabaseService()
    private let cellId = "cell"
    private var currentEpisodes = [Episode]()
    weak var delegate: DetailEpisodeDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        configureDatabase()
        configureFirstView()
        configureSecondView()
        configureButton()
        selectInDependent(from: .recent)
    }
    
    private func configureDatabase() {
        dbService.createTable()
    }
    
    private func configureFirstView() {
        addSubview(firstView)
        firstView.backgroundColor = .white
        firstView.translatesAutoresizingMaskIntoConstraints = false
        firstView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        firstView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        firstView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        firstView.widthAnchor.constraint(equalToConstant: self.frame.width / 2).isActive = true
    }
    
    private func configureSecondView() {
        addSubview(secondView)
        secondView.register(SlidePanelTableViewCell.self, forCellReuseIdentifier: cellId)
        secondView.dataSource = self
        secondView.delegate = self
        secondView.separatorStyle = .none
        
        secondView.contentInset = .init(top: 100, left: 0, bottom: 0, right: 0)
        secondView.backgroundColor = .black
        secondView.translatesAutoresizingMaskIntoConstraints = false
        secondView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        secondView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        secondView.leadingAnchor.constraint(equalTo: firstView.trailingAnchor).isActive = true
        secondView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    private func configureButton() {
        firstView.addSubview(recentButton)
        recentButton.isSelected = true
        recentButton.setAttributedTitle(customAttributedString(with: "최근 들은 에피소드", isSelected: recentButton.isSelected), for: .normal)
        recentButton.frame.size = CGSize(width: 100, height: 40)
        recentButton.translatesAutoresizingMaskIntoConstraints = false
        recentButton.centerYAnchor.constraint(equalTo: firstView.centerYAnchor, constant: -30).isActive = true
        recentButton.centerXAnchor.constraint(equalTo: firstView.centerXAnchor).isActive = true
        recentButton.addTarget(self, action: #selector(touchedRecent), for: .touchUpInside)
        
        firstView.addSubview(favoriteButton)
        recentButton.isSelected = false
        favoriteButton.setAttributedTitle(customAttributedString(with: "좋아하는 에피소드", isSelected: recentButton.isSelected), for: .normal)
        favoriteButton.frame.size = CGSize(width: 100, height: 40)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.centerYAnchor.constraint(equalTo: firstView.centerYAnchor, constant: 30).isActive = true
        favoriteButton.centerXAnchor.constraint(equalTo: firstView.centerXAnchor).isActive = true
        favoriteButton.addTarget(self, action: #selector(touchedFavorite), for: .touchUpInside)
    }
    
    private func customAttributedString(with text: String, isSelected: Bool) -> NSAttributedString {
        var attributedOption = [NSAttributedString.Key: Any]()
        if isSelected {
            attributedOption.updateValue(2, forKey: .underlineStyle)
            attributedOption.updateValue(UIFont.boldSystemFont(ofSize: 20), forKey: .font)
            attributedOption.updateValue(UIColor.black, forKey: .foregroundColor)
        } else {
            attributedOption.updateValue(UIFont.boldSystemFont(ofSize: 20), forKey: .font)
            attributedOption.updateValue(UIColor.gray, forKey: .foregroundColor)
        }
        let attributedString = NSAttributedString(string: text, attributes: attributedOption)
        return attributedString
    }
    
    @objc private func touchedRecent() {
        selectInDependent(from: .recent)
        switchSelectedButton(activatedButton: .recent)
    }
    
    @objc private func touchedFavorite() {
        selectInDependent(from: .favorite)
        switchSelectedButton(activatedButton: .favorite)
    }
    
    private func switchSelectedButton(activatedButton: ButtonCategory) {
        let selectedButton = activatedButton == .recent ? recentButton : favoriteButton
        let unSelectedButton = activatedButton == .recent ? favoriteButton : recentButton
        selectedAttributed(with: selectedButton)
        unSelectedAttributed(with: unSelectedButton)
    }

    private func selectInDependent(from category: TableCategory) {
        guard let episodes = dbService.selectInDependent(from: category) else { return }
        if episodes.count > 0 {
            currentEpisodes = episodes
            secondView.reloadData()
            let indexPath = IndexPath(row: 0, section: 0)
            secondView.scrollToRow(at: indexPath, at: .middle, animated: false)
        } else {
            currentEpisodes.removeAll()
            secondView.reloadData()
        }
    }
    
    private func selectedAttributed(with button: UIButton) {
        guard let title = button.titleLabel?.text else { return }
        button.isSelected = true
        button.setAttributedTitle(customAttributedString(with: title, isSelected: button.isSelected), for: .normal)
    }
    
    private func unSelectedAttributed(with button: UIButton) {
        guard let title = button.titleLabel?.text else { return }
        button.isSelected = false
        button.setAttributedTitle(customAttributedString(with: title, isSelected: button.isSelected), for: .normal)
    }
}

extension SlidePanelContainerView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentEpisodes.count > 0 {
            secondView.backgroundView = nil
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: secondView.bounds.size.width, height: secondView.bounds.size.height))
            noDataLabel.text = "에피소드가 없습니다."
            noDataLabel.textColor = UIColor.white
            noDataLabel.textAlignment = .center
            secondView.backgroundView = noDataLabel
        }
        return currentEpisodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = secondView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SlidePanelTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: currentEpisodes[indexPath.row])
        return cell
    }
}

extension SlidePanelContainerView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 해당 뷰 대신 이 뷰를 가진 컨트롤러에서 처리하도록 delegate 패턴을 사용합니다.
        let episode = currentEpisodes[indexPath.row]
        delegate?.touchedEpisode(with: episode)
    }
}
