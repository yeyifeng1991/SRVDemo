//
//  SRVpnTableCell.m
//  SRVDemo
//
//  Created by yyf on 2025/6/21.
//

#import "SRVpnTableCell.h"
#import <Masonry/Masonry.h>
@interface SRVpnTableCell()
// 左侧显示的圆圈图标（可根据选中状态控制显示隐藏）
@property (nonatomic, strong) UIImageView *leftCircleImageView;
// 主标题标签
@property (nonatomic, strong) UILabel *proxyNameLabel;
// 副标题标签
@property (nonatomic, strong) UILabel *procyTypeLabel;

@end
@implementation SRVpnTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 初始化左侧圆圈图标
        self.leftCircleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tk_pointGray"]]; // 假设正常状态图片叫 left_circle_normal
        [self.contentView addSubview:self.leftCircleImageView];
        [self.leftCircleImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_offset(16);
            make.centerY.mas_equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        // 初始化主标题标签
        self.proxyNameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.proxyNameLabel];
        [self.proxyNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.leftCircleImageView.mas_right).offset(10);
            make.top.mas_offset(12);
        }];
        
        // 初始化副标题标签
        self.procyTypeLabel = [[UILabel alloc] init];
        [self.contentView addSubview: self.procyTypeLabel];
        [self.procyTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.proxyNameLabel.mas_bottom).offset(5);
            make.left.mas_equalTo(self.proxyNameLabel);
        }];

    }
    return self;
}

- (void)setProxyModel:(ClashProxyModel *)proxyModel
{
    _proxyModel = proxyModel;
    self.proxyNameLabel.text = proxyModel.name;
    switch (proxyModel.type) {
        case ClashProxyTypeSS:
            self.procyTypeLabel.text = @"ClashProxyTypeSS";
            break;
        case ClashProxyTypeTrojan:
            self.procyTypeLabel.text = @"ClashProxyTypeTrojan";
            break;
        case ClashProxyTypeUnknown:
            self.procyTypeLabel.text = @"";
            break;
        default:
            break;
    }
    switch (proxyModel.connectType) {
        case ClashConnectDefault:
            self.leftCircleImageView.image = [UIImage imageNamed:@"tk_pointGray"];
            break;
        case ClashConnectSuccess:
            self.leftCircleImageView.image = [UIImage imageNamed:@"tk_pointGreen"];
            break;
        case ClashConnectFail:
            self.leftCircleImageView.image = [UIImage imageNamed:@"tk_pointRed"];
            break;
            
        default:
            break;
    }
    
    
}


@end
