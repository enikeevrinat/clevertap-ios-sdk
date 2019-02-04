#import "CTInboxSimpleMessageCell.h"

@implementation CTInboxSimpleMessageCell

- (void)setup {
    self.avPlayerContainerView.hidden = YES;
    self.actionView.hidden = YES;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOnMessageTapGesture:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cellImageView sd_cancelCurrentAnimationImagesLoad];
    self.cellImageView.animatedImage = nil;
}

- (void)doLayoutForMessage:(CleverTapInboxMessage *)message {
    if (!message.content || message.content.count < 0) {
        return;
    }
    CleverTapInboxMessageContent *content = message.content[0];
    self.cellImageView.hidden = YES;
    self.avPlayerControlsView.alpha = 0.0;
    self.avPlayerContainerView.hidden = YES;
    self.activityIndicator.hidden = YES;
    if ([self mediaIsEmpty]) {
        self.imageViewHeightConstraint.priority = 999;
        self.imageViewLRatioConstraint.priority = 750;
        self.imageViewPRatioConstraint.priority = 750;
    } else if ([self orientationIsPortrait]) {
        self.imageViewPRatioConstraint.priority = 999;
        self.imageViewLRatioConstraint.priority = 750;
        self.imageViewHeightConstraint.priority = 750;
    } else {
        self.imageViewHeightConstraint.priority = 750;
        self.imageViewPRatioConstraint.priority = 750;
        self.imageViewLRatioConstraint.priority = 999;
    }
    [self configureActionView:!content.actionHasLinks];
    self.playButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.playButton.layer.borderWidth = 2.0;
    self.titleLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.titleColor];
    self.bodyLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.messageColor];
    self.dateLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.titleColor];
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupMessage:(CleverTapInboxMessage *)message {
    if (!message.content || message.content.count < 0) {
        self.cellImageView.image = nil;
        self.cellImageView.animatedImage = nil;
        self.titleLabel.text = nil;
        self.bodyLabel.text = nil;
        self.dateLabel.text = nil;
        return;
    }
    
    CleverTapInboxMessageContent *content = message.content[0];
    self.cellImageView.image = nil;
    self.cellImageView.animatedImage = nil;
    self.cellImageView.clipsToBounds = YES;
    self.titleLabel.text = content.title;
    self.bodyLabel.text = content.message;
    self.dateLabel.text = message.relativeDate;
    self.readView.hidden = message.isRead;
    self.readViewWidthConstraint.constant = message.isRead ? 0 : 16;
    [self setupInboxMessageActions:content];
    self.cellImageView.contentMode = content.mediaIsGif ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    if (content.mediaUrl && !content.mediaIsVideo && !content.mediaIsAudio) {
        self.cellImageView.hidden = NO;
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                              placeholderImage:[self orientationIsPortrait] ? [self getPortraitPlaceHolderImage] : [self getLandscapePlaceHolderImage] options:self.sdWebImageOptions];
    } else if (content.mediaIsVideo || content.mediaIsAudio) {
        [self setupMediaPlayer];
    }
}

@end
