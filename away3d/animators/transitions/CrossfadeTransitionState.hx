/**
 *
 */
package away3d.animators.transitions;

import away3d.animators.states.SkeletonBinaryLERPState;
import away3d.events.AnimationStateEvent;

class CrossfadeTransitionState extends SkeletonBinaryLERPState {

    private var _skeletonAnimationNode:CrossfadeTransitionNode;
    private var _animationStateTransitionComplete:AnimationStateEvent;

    function new(animator:IAnimator, skeletonAnimationNode:CrossfadeTransitionNode) {
        super(animator, skeletonAnimationNode);
        _skeletonAnimationNode = skeletonAnimationNode;
    }

/**
	 * @inheritDoc
	 */

    override private function updateTime(time:Int):Void {
        blendWeight = Math.abs(time - _skeletonAnimationNode.startBlend) / (1000 * _skeletonAnimationNode.blendSpeed);
        if (blendWeight >= 1) {
            blendWeight = 1;
            _skeletonAnimationNode.dispatchEvent(_animationStateTransitionComplete || = new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _skeletonAnimationNode));
        }
        super.updateTime(time);
    }

}

